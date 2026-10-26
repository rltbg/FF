# F* → F# → Avalonia : test de la boucle de développement

Banc d'essai (F* 2026.10.25, .NET SDK 10.0.403, Avalonia 12.1.4) d'une application MVU dont le modèle,
`update`, `view` (arbre de vue en donnée) et la validation sont écrits et prouvés en F*, extraits en F#
(`--codegen FSharp`, backend Custard), puis affichés par un petit interpréteur Avalonia.
Hot reload en dev (hôte `AssemblyLoadContext`), NativeAOT en release.

**Verdict : boucle viable avec contournements mineurs.** Rapport complet : [REPORT.md](REPORT.md).

## Contenu
| Dossier | Rôle |
|---|---|
| `fst/Core.fst`, `fst/App.fst` | Logique vérifiée (FNV-1a, analyse décimale bornée, modèle, update, view) |
| `app/Extracted/` | F# extrait tel quel (`Extracted.fs`) + bibliothèque Custard générée (`FStarCustard.fs`) |
| `app/Ui/` | Interpréteur générique `Node → contrôles Avalonia` + boucle MVU (seule couche qui connaît Avalonia) |
| `app/HostStatic/` | Hôte lié statiquement au cœur (JIT et NativeAOT) |
| `app/HostDev/` | Hôte de dev : recharge `Extracted.dll` à chaud et transfère le modèle |
| `app/Tests/` | 683 322 vérifications (JIT et AOT) + benchmark (`Tests bench`) |
| `scripts/` | `loop.sh` (cycle chronométré), `startup.sh` (démarrage + RSS) |
| `logs/` | Logs bruts (`aot_err.log` = plantage AOT corrigé depuis : `string` sur une union F#) |
| `shots/` | Captures Xvfb |

## Reproduire
```
# F* : https://github.com/FStarLang/FStar/releases/download/v2026.10.25/fstar-v2026.10.25-Linux-x86_64.tar.gz
# .NET : dotnet-install.sh --channel 10.0
cd fst
A="--odir _output --cache_dir _cache --already_cached Prims,FStar --warn_error -321"
fstar.exe $A --cache_checked_modules Core.fst
fstar.exe $A --cache_checked_modules App.fst
fstar.exe $A --codegen FSharp --custard_entry_module Core --custard_entry_module App App.fst -o ../app/Extracted/Extracted.fs
cd ../app && dotnet publish HostStatic -c Release -r linux-x64 -p:PublishAot=true
```
Les modules F* se vérifient dans l'ordre des dépendances (Core avant App). `scripts/*.sh` contiennent des chemins
absolus de la machine d'essai (`/home/user/w/...`) à adapter. Interface sous Xvfb (`DISPLAY=:99`), rendu logiciel X11.
