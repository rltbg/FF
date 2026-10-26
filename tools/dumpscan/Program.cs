// Analyse d'un dump (dotnet-dump collect) pour trouver ce qui retient un AssemblyLoadContext collectible.
// usage : DAC=<.../libmscordaccore.so> dotnet run -- <core.dmp>
// 1) calcule les objets vivants depuis les vraies racines (pile, poignées fortes, statiques) ;
// 2) pour chaque System.Reflection.LoaderAllocator, remonte les référenceurs sur 8 niveaux ;
// 3) affiche le chemin racine -> premier Avalonia.Controls.Button retenant le LoaderAllocator #0
//    (adapter le type recherché pour un autre cas).
using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Diagnostics.Runtime;

var dump = args[0];
using var dt = DataTarget.LoadDump(dump);
using var rt = dt.ClrVersions[0].CreateRuntime(Environment.GetEnvironmentVariable("DAC"), true);
var heap = rt.Heap;

// 1. objets de la heap + modules "Extracted.dll"
var mods = rt.EnumerateModules().Where(m => (m.Name ?? "").EndsWith("Extracted.dll")).ToList();
Console.WriteLine("modules Extracted: " + string.Join(", ", mods.Select(m => m.Address.ToString("x"))));
var las = heap.EnumerateObjects().Where(o => o.Type?.Name == "System.Reflection.LoaderAllocator").ToList();
Console.WriteLine("LoaderAllocator: " + string.Join(", ", las.Select(o => o.Address.ToString("x"))));

// 2. ensemble vivant depuis les racines "fortes"
var live = new HashSet<ulong>();
var parent = new Dictionary<ulong, ulong>();
var rootOf = new Dictionary<ulong, string>();
var stack = new Stack<ulong>();
var rootKinds = new Dictionary<string,int>();
foreach (var r in heap.EnumerateRoots())
{
    var k = r.RootKind.ToString() + (r.IsInterior ? "(int)" : "");
    rootKinds[k] = rootKinds.GetValueOrDefault(k) + 1;
    if (r.Object.Address != 0 && live.Add(r.Object.Address)) { stack.Push(r.Object.Address); rootOf[r.Object.Address] = r.RootKind + " " + " " + r.ToString() ; }
}
Console.WriteLine("racines: " + string.Join(", ", rootKinds.Select(kv => kv.Key + "=" + kv.Value)));
while (stack.Count > 0)
{
    var a = stack.Pop();
    var o = heap.GetObject(a);
    if (!o.IsValid) continue;
    foreach (var r in o.EnumerateReferences())
        if (r.Address != 0 && live.Add(r.Address)) { stack.Push(r.Address); parent[r.Address] = a; }
}
Console.WriteLine("objets vivants atteints: " + live.Count);

// 3. pour chaque LA : est-il atteint ? par qui (référenceurs vivants directs) ?
var allObjs = heap.EnumerateObjects().ToList();
var refsTo = new Dictionary<ulong, List<ulong>>();
foreach (var o in allObjs)
{
    if (!o.IsValid) continue;
    foreach (var r in o.EnumerateReferences())
    {
        if (r.Address == 0) continue;
        if (!refsTo.TryGetValue(r.Address, out var l)) refsTo[r.Address] = l = new List<ulong>();
        l.Add(o.Address);
    }
}
foreach (var la in las)
{
    Console.WriteLine($"\n=== LA {la.Address:x} atteint par les racines fortes: {live.Contains(la.Address)}");
    // BFS arrière sur les référenceurs, profondeur 8, en ne montrant que les objets VIVANTS
    var seen = new HashSet<ulong> { la.Address };
    var frontier = new List<ulong> { la.Address };
    for (int depth = 1; depth <= 8 && frontier.Count > 0; depth++)
    {
        var next = new List<ulong>();
        var byType = new Dictionary<string,int>();
        foreach (var t in frontier)
            if (refsTo.TryGetValue(t, out var rs))
                foreach (var r in rs)
                    if (seen.Add(r)) { next.Add(r); var o = heap.GetObject(r); var n = (o.Type?.Name ?? "?") + (live.Contains(r) ? " [VIVANT]" : ""); byType[n] = byType.GetValueOrDefault(n) + 1; }
        Console.WriteLine($"  niveau {depth}: " + string.Join(" | ", byType.OrderByDescending(kv => kv.Value).Take(8).Select(kv => kv.Value + "× " + kv.Key)));
        frontier = next;
    }
}

// chemin racine -> bouton retenant le LA fuyant (le 1er de la liste)
var leaked = las[0].Address;
var btn = new List<ulong>();
foreach (var o in allObjs)
    if (o.Type?.Name == "Avalonia.Controls.Button" && live.Contains(o.Address)) btn.Add(o.Address);
Console.WriteLine("\nButtons vivants: " + btn.Count);
// identifier ceux qui retiennent le LA fuyant : on suit refsTo depuis LA jusqu'à 5 niveaux
var holdBtn = new HashSet<ulong>();
{
    var seen = new HashSet<ulong>{ leaked }; var fr = new List<ulong>{ leaked };
    for (int d = 1; d <= 6 && fr.Count > 0; d++) {
        var nx = new List<ulong>();
        foreach (var t in fr) if (refsTo.TryGetValue(t, out var rs)) foreach (var r in rs) if (seen.Add(r)) { nx.Add(r); if (heap.GetObject(r).Type?.Name == "Avalonia.Controls.Button") holdBtn.Add(r); }
        fr = nx;
    }
}
Console.WriteLine("Buttons retenant le LA fuyant: " + holdBtn.Count);
foreach (var b in holdBtn.Take(1))
{
    Console.WriteLine("\nCHEMIN racine -> Button " + b.ToString("x") + " :");
    var chain = new List<ulong>(); var cur = b;
    while (true) { chain.Add(cur); if (parent.TryGetValue(cur, out var pp)) cur = pp; else break; }
    chain.Reverse();
    Console.WriteLine("  racine: " + (rootOf.TryGetValue(chain[0], out var rk) ? rk : "?"));
    foreach (var a in chain) Console.WriteLine("   -> " + a.ToString("x") + " " + heap.GetObject(a).Type?.Name);
}

