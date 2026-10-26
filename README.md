# F* → F# → Avalonia : test de la boucle de développement

Banc d'essai d'une application MVU dont le modèle, `update`, `view` (arbre de vue en donnée) et la validation sont
écrits et prouvés en F*, extraits en F# (`--codegen FSharp`, backend Custard), puis affichés par un petit
interpréteur Avalonia. Rechargement à chaud en dev (hôte `AssemblyLoadContext`), NativeAOT en release.

Versions : F* 2026.10.25 · .NET SDK 10.0.403 · Avalonia 12.1.4 · FSharp.Core 10.1.403.

**Verdict : boucle viable avec contournements mineurs.** Rapport complet (2e passe, revue contre les documentations) :
[REPORT.md](REPORT.md).

## Contenu
| Chemin | Rôle |
|---|---|
| `fst/Core.fst` | FNV-1a 32 bits (spec liste + implémentation `byte[]` prouvée égale, empreinte UTF-8), analyse décimale bornée (correction fonctionnelle prouvée), validation de nom |
| `fst/App.fst` | Modèle, messages, `update` avec invariant prouvé, `view` → arbre de vue |
| `app/Extracted/` | F# extrait tel quel + bibliothèque Custard générée (régénérés par `scripts/extract.sh`) |
| `app/Ui/` | Interpréteur réconciliant `Node` → contrôles Avalonia, boucle MVU, démarrage (`UsePlatformDetect`) |
| `app/HostStatic/` | Hôte lié statiquement au cœur (JIT et NativeAOT) |
| `app/HostDev/` | Hôte de dev : recharge `Extracted.dll` à chaud, transfère le modèle, mesure le déchargement |
| `app/Tests/` | 949 803 vérifications (JIT et AOT) ; `Tests bench` pour les micro-mesures |
| `tools/dumpscan/` | Analyseur ClrMD de dumps : qui retient un `AssemblyLoadContext` collectible (a servi à trouver la fuite du premier contexte, voir REPORT §5) |
| `scripts/` | Voir ci-dessous |
| `logs/`, `shots/` | Journaux bruts et captures de la dernière exécution |

## Utilisation
```
scripts/setup.sh        # F* et SDK .NET dans .tools/ (versions épinglées)
scripts/all.sh          # passe complète depuis zéro : extraction, build + AOT, tests, GUI, rechargement, mutations
```
Scripts unitaires : `extract.sh [full|admit|lax]`, `build.sh`, `test.sh`, `ui_smoke.sh <cmd>`, `hotreload.sh`,
`mutate.sh`, `loop.sh [mode]`, `loop_bench.sh`, `startup.sh <label> <cmd>`, `watch_check.sh`.
Les tests GUI utilisent Xvfb (`:99`), `xdotool`, `xwininfo`/`xprop` (paquet `x11-utils`) et ImageMagick.
`MVU_SOFTWARE_RENDERING=1` force le rendu X11 logiciel ; `MVU_TRACE=<fichier>` journalise le modèle après chaque rendu.
