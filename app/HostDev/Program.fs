module Program

open System
open System.IO
open System.Runtime.CompilerServices
open Avalonia.Threading
open Ui

let stamp () = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()

/// Signature du fichier surveillé. Sondage plutôt que FileSystemWatcher : dans le conteneur de test,
/// la réécriture de la DLL par MSBuild ne produisait aucun événement inotify (un `touch` en produisait).
let fileSig (path: string) =
  let fi = FileInfo path
  if fi.Exists then fi.LastWriteTimeUtc.Ticks ^^^ fi.Length else 0L

/// Combien des anciens contextes sont encore vivants après GC (déchargement coopératif, doc .NET).
[<MethodImpl(MethodImplOptions.NoInlining)>]
let aliveAfterGc (olds: ResizeArray<WeakReference>) =
  for _ in 1 .. 10 do
    GC.Collect()
    GC.WaitForPendingFinalizers()
  [ for i in 0 .. olds.Count - 1 do if olds.[i].IsAlive then yield i ]

/// Textes affichés (aplatis) : oracle des tests de rechargement.
let rec texts (n: Node) : string list =
  match n with
  | Column xs | Row xs -> List.collect texts xs
  | Heading s | Text s -> [ s ]
  | Button (l, _) | Check (l, _, _) -> [ l ]
  | Input (_, v, _) -> [ v ]
  | BigList (src, r, sel) -> [ "BigList " + string src + "/" + string r + " sel=" + string sel ]
  | BigText (src, n) -> [ "BigText " + string src + "/" + string n ]

[<EntryPoint>]
let main argv =
  if argv.Length < 1 then failwith "usage: HostDev <Extracted.dll> [journal]"
  let path = Path.GetFullPath argv.[0]
  let logPath = if argv.Length > 1 then argv.[1] else "/dev/null"
  let log (s: string) = File.AppendAllText(logPath, string (stamp ()) + " " + s + "\n")
  let olds = ResizeArray<WeakReference>()
  let current : Reload.CoreAlc ref = ref Unchecked.defaultof<_>

  let reload (r: Runner) =
    let t0 = stamp ()
    let alc, api, modelType = Reload.load path
    let model, status =
      match Reload.tryTransplant r.Model modelType with
      | Ok m -> m, "model-kept"
      | Error why -> api.Init, "model-RESET (" + why + ")"
    r.Swap(api, model)
    current.Value.Unload()
    olds.Add(WeakReference current.Value)
    current.Value <- alc
    log ("reloaded " + status + " ms=" + string (stamp () - t0))

  /// Premier chargement, une fois la fenêtre ouverte (boucle du dispatcher active).
  let start (w: Avalonia.Controls.Window) =
    let alc, api, _ = Reload.load path
    current.Value <- alc
    let r = Runner(api, w)
    r.OnRender <- fun m -> log ("render " + String.Join(" | ", texts (r.CurrentApi.View m)))
    r.Render()
    log "ready"
    // rechargement quand la signature a changé puis est restée stable pendant une période (écriture finie)
    let seen = ref (fileSig path)
    let loaded = ref seen.Value
    let timer = new Timers.Timer(200.0)
    timer.Elapsed.Add(fun _ ->
      let s = fileSig path
      if s <> seen.Value then seen.Value <- s
      elif s <> loaded.Value && s <> 0L then
        loaded.Value <- s
        log "change-detected"
        Dispatcher.UIThread.Post(fun () ->
          try reload r with e -> log ("reload-error " + e.GetType().Name + ": " + e.Message)))
    timer.Start()
    // contrôle périodique du déchargement (journalisé seulement quand le nombre change)
    let lastAlive = ref ""
    DispatcherTimer.Run((fun () ->
      if olds.Count > 0 then
        let alive = aliveAfterGc olds
        let txt = string alive.Length + "/" + string olds.Count + " vivants=" + String.Join(",", alive)
        if txt <> lastAlive.Value then
          lastAlive.Value <- txt
          log ("alc-alive " + txt)
      true), TimeSpan.FromSeconds 2.0) |> ignore

  Startup.run [||] (fun lt ->
    let w = Startup.newWindow ()
    lt.MainWindow <- w
    w.Opened.Add(fun _ -> start w))
