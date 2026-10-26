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
| `app/Tests/` | 950 851 vérifications (JIT et AOT) ; `Tests bench` pour les micro-mesures et le coût de 100 000 éléments dans le modèle F* |
| `tools/dumpscan/` | Analyseur ClrMD de dumps : qui retient un `AssemblyLoadContext` collectible (a servi à trouver la fuite du premier contexte, voir REPORT §5) |
| `docs/GUIDE.md` | **Tout** : architecture, règles pour écrire du F* qui s'extrait, hôte, boucle de dev, gros volumes, AOT, extension |
| `docs/STATUT.md` | Ce qui est fait / limité / pas fait / impossible ici |
| `docs/MATRICE-FSTAR.md`, `docs/matrix/`, `docs/scale/` | 28 cas d'extraction F* → F# exécutés, et passage à l'échelle de `Seq`/`Map`/`Set`/`RBMap` |
| `docs/UPSTREAM-FSTAR.md`, `docs/FSTAR-char_code.md`, `docs/repro/` | Défauts de F* constatés (dont `/` et `%` de `Prims.int`, `u32_of_char`), preuves et correctifs proposés — **non déposés** |
| `docs/TODO-avalonia-upstream.md` | Défaut Avalonia 12.1.4 constaté (`ScrollContentPresenter`) : à reproduire et remonter plus tard |
| `CLAUDE.md` | Règles de travail : **lire la doc et le code source de F*, Custard et Avalonia avant d'écrire**, méthode, pièges connus |
| `scripts/` | Voir ci-dessous |
| `logs/`, `shots/` | Journaux bruts et captures de la dernière exécution |

## Utilisation
```
scripts/setup.sh        # F* et SDK .NET dans .tools/ (versions épinglées)
scripts/sources.sh      # code source de F* et d'Avalonia aux mêmes versions, dans .tools/src/ (à lire avant d'écrire)
scripts/all.sh          # passe complète depuis zéro : extraction, build + AOT, tests, GUI, rechargement, mutations
```
Scripts unitaires : `extract.sh [full|admit|lax]`, `build.sh`, `test.sh`, `ui_smoke.sh <cmd>`, `hotreload.sh`,
`mutate.sh`, `matrix.sh`, `scale.sh`, `repro_char_code.sh`, `loop.sh [mode]`, `loop_bench.sh`, `startup.sh <label> <cmd>`,
`list_scale.sh <cmd>`, `watch_check.sh`. Pas d'intégration continue GitHub Actions (décision de l'utilisateur) : `scripts/all.sh` est la passe complète.
Les tests GUI utilisent Xvfb (`:99`), `xdotool`, `xwininfo`/`xprop` (paquet `x11-utils`) et ImageMagick.
`MVU_SOFTWARE_RENDERING=1` force le rendu X11 logiciel ; `MVU_TRACE=<fichier>` journalise le modèle après chaque rendu.
