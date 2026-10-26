# F* → F# → Avalonia : test de la boucle de développement

Banc d'essai d'une application MVU dont le modèle, `update`, `view` (arbre de vue en donnée) et la validation sont
écrits et prouvés en F*, extraits en F# (`--codegen FSharp`, backend Custard), puis affichés par un petit
interpréteur Avalonia. Rechargement à chaud en dev (hôte `AssemblyLoadContext`, JIT, sur la machine du développeur : `scripts/dev.sh`), NativeAOT en release (une construction par plateforme dans la CI).

Versions : F* 2026.10.25 · .NET SDK 10.0.403 · Avalonia 12.1.4 · FSharp.Core 10.1.403.

**Verdict : boucle viable avec contournements mineurs.** Rapport complet (2e passe, revue contre les documentations) :
[REPORT.md](REPORT.md).

## Contenu
| Chemin | Rôle |
|---|---|
| `fst/Core.fst` | FNV-1a 32 bits (spec liste + implémentation `byte[]` prouvée égale, empreinte UTF-8), analyse décimale bornée (correction fonctionnelle prouvée), validation de nom |
| `fst/Big.fst` | Données volumineuses **générées par F\*** à la demande (100 000 lignes, texte de 1 Mo) et leurs réciproques prouvées |
| `fst/App.fst` | Modèle, messages, `update` avec invariant prouvé, `view` → arbre de vue, `show_model` (journal de test), `preload_msgs` |
| `app/Extracted/` | F# extrait tel quel + bibliothèque Custard générée (**non versionnés** : produits par `scripts/extract.sh`, et par le job `extract` de la CI) |
| `app/Ui/` | Interpréteur réconciliant `Node` → contrôles Avalonia, boucle MVU, cycle de vie multi-plateforme (Avalonia noyau seul) |
| `app/Shell/`, `app/UiDesktop/` | Colle commune à toutes les têtes ; démarrage bureau (`UsePlatformDetect`) |
| `app/HostStatic/`, `HostBrowser/`, `HostAndroid/`, `HostIOS/` | Têtes : **bureau** (Windows, macOS, Linux ; JIT/NativeAOT), **navigateur** (WebAssembly), **Android**, **iOS** (écrite, non compilable sous Linux) |
| `app/HostDev/` | Hôte de dev : recharge `Extracted.dll` à chaud, transfère le modèle, mesure le déchargement |
| `ftests/` | **Tous les tests, en F\*** (aucun test en F#) : 1 490 342 vérifications en JIT et en AOT ; générateurs `scripts/gen_tmachine.py`, `gen_tulib.py` |
| `tools/dumpscan/` | Analyseur ClrMD de dumps : qui retient un `AssemblyLoadContext` collectible (a servi à trouver la fuite du premier contexte, voir REPORT §5) |
| `docs/ULIB-COUVERTURE.md` + `COUVERTURE-*.md` | Test de « toutes les fonctions F* » : méthode, couverture mesurée (171/187 réalisations, 49 % des définitions exécutables d'ulib atteintes), écarts trouvés |
| `docs/NATIVEAOT.md` | **NativeAOT sur toutes les plateformes** : ce que dit la documentation (pas de cross-OS ; Android expérimental ; pas de navigateur), ce qui a été essayé, ce qui reste |
| `docs/PLATEFORMES.md` | **Compiler vers toutes les plateformes** : architecture des têtes, ce qui se construit ici (bureau ×8 RID, NativeAOT, navigateur, Android), ce qui ne se construit pas (iOS), ce qui n'est pas vérifié |
| `docs/GUIDE.md` | **Tout** : architecture, règles pour écrire du F* qui s'extrait, hôte, boucle de dev, gros volumes, AOT, extension |
| `docs/STATUT.md` | Ce qui est fait / limité / pas fait / impossible ici |
| `docs/MATRICE-FSTAR.md`, `docs/matrix/`, `docs/scale/` | 46 cas d'extraction F* → F# exécutés, et passage à l'échelle de `Seq`/`Map`/`Set`/`RBMap` |
| `docs/UPSTREAM-FSTAR.md`, `docs/FSTAR-char_code.md`, `docs/repro/` | Défauts de F* constatés (dont `/` et `%` de `Prims.int`, `u32_of_char`), preuves et correctifs proposés — **non déposés** |
| `docs/TODO-avalonia-upstream.md` | Défaut Avalonia 12.1.4 constaté (`ScrollContentPresenter`) : à reproduire et remonter plus tard |
| `CLAUDE.md` | Règles de travail : **lire la doc et le code source de F*, Custard et Avalonia avant d'écrire**, méthode, pièges connus |
| `scripts/` | Voir ci-dessous |
| `logs/`, `shots/` | Journaux bruts et captures de la dernière exécution |

## Utilisation
```
scripts/setup.sh        # F* et SDK .NET dans .tools/ (versions épinglées)
scripts/sources.sh      # code source de F* et d'Avalonia aux mêmes versions, dans .tools/src/ (à lire avant d'écrire)
scripts/dev.sh          # DEV : fenêtre en JIT sur votre machine (`dev.sh watch` : rechargement à chaud à chaque sauvegarde de fst/*.fst)
scripts/all.sh          # passe complète depuis zéro : extraction, build + AOT (Linux x64), tests, GUI, rechargement, mutations
```
Tests : `ftests.sh` (suite F*), `upstream_tests.sh` (tests amont de F* via le backend F#), `ulib_sweep.sh` (221 modules d'ulib), `bench_model.sh`, `loc.sh`. Plateformes : `platforms_setup.sh`, `platforms.sh [cible]`, `browser_smoke.sh`. Scripts unitaires : `extract.sh [full|admit|lax]`, `build.sh`, `test.sh`, `ui_smoke.sh <cmd>`, `hotreload.sh`,
`mutate.sh`, `matrix.sh`, `scale.sh`, `repro_char_code.sh`, `loop.sh [mode]`, `loop_bench.sh`, `startup.sh <label> <cmd>`,
`list_scale.sh <cmd>`, `watch_check.sh`. GitHub Actions ne sert qu'à construire les plateformes (`.github/workflows/build.yml`, voir `docs/CI.md` ; dernier run complet : 9 jobs verts) ; `scripts/all.sh` reste la passe complète de tests.
Les tests GUI utilisent Xvfb (`:99`), `xdotool`, `xwininfo`/`xprop` (paquet `x11-utils`) et ImageMagick.
`MVU_SOFTWARE_RENDERING=1` force le rendu X11 logiciel ; `MVU_TRACE=<fichier>` journalise le modèle après chaque rendu.
