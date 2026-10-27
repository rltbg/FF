# Règles de travail sur ce dépôt

Ce dépôt est un banc d'essai **F\* → F# → Avalonia** (NativeAOT). F*, son backend F# « Custard » et Avalonia 12 sont des
outils **peu courants** : ne jamais deviner une syntaxe, une API, une précondition ou un comportement.

## 1. Lire avant d'écrire

Avant d'écrire ou de modifier du code qui s'appuie sur F*, Custard, Avalonia ou le runtime .NET :

1. `scripts/sources.sh` récupère les **sources aux versions exactes** dans `.tools/src/` (non versionné) :
   - **F\*** (`.tools/src/FStar`) : `ulib/*.fsti` (signatures **et préconditions** de la bibliothèque), `src/custard/FStarC.Custard.PrintFSharp.fst`
     (`supported_realizations`, `builtin_type`, `reject_*` : ce que le backend F# accepte), `doc/ref/custard.md` (§122 = backend F#),
     `tests/custard/` (exemples qui compilent), et `fstar.exe --help` (options).
   - **Avalonia** (`.tools/src/Avalonia/src`) : le code des contrôles utilisés (`Avalonia.Controls`, `Avalonia.Base`, `Avalonia.X11`…),
     plus la doc XML des paquets (`~/.nuget/packages/*/lib/*/*.xml`) et `docs.avaloniaui.net`.
   - **.NET** : `learn.microsoft.com` (AssemblyLoadContext, NativeAOT, Hot Reload) ; le runtime est sur `github.com/dotnet/runtime`.
2. Lire le **corps** du code concerné, pas seulement la documentation : la doc de Custard se décrit comme « design sketch »,
   et deux défauts de ce dépôt (`docs/UPSTREAM-FSTAR.md`, `docs/TODO-avalonia-upstream.md`) n'étaient visibles que dans le code.
3. Si la source ne répond pas, **écrire un cas minimal et l'exécuter** (`docs/matrix/`, `scripts/matrix.sh`) plutôt que supposer.

## 2. Règles de méthode

- Ne jamais annoncer qu'une étape réussit sans l'avoir exécutée ; garder les erreurs exactes. Une étape impossible est un résultat.
- `scripts/all.sh` (≈ 25 min) doit finir par « TOUT OK » avant de conclure ; mettre à jour `README.md`, `REPORT.md`, `docs/STATUT.md`
  quand un chiffre ou un comportement change.
- Pour chaque contournement : l'erreur exacte, la version, « inévitable » (défaut de la version) ou « évitable » (mon choix de code).
- Ne pas déposer de ticket ni publier quoi que ce soit en dehors de ce dépôt sans accord explicite de l'utilisateur.
- **GitHub Actions** : uniquement pour construire les plateformes (`.github/workflows/build.yml`, `docs/CI.md`), jamais sur un simple push ; ne pas la lancer ni consommer de minutes sans accord ; les tests restent `scripts/all.sh`. Ne citer aucun numéro de ticket qu'on n'a pas lu soi-même.
- Les mesures sont faites sous Xvfb sans GPU : ne jamais les présenter comme valables pour un GPU ou le mobile.

## 3. Pièges connus (détails dans `docs/`)

- F* : un produit de types s'écrit `&`, pas `*` ; `opaque` est un mot réservé ; `-x` sur un `int` non constant n'est pas extractible
  (écrire `0 - a`) ; `/` et `%` de `Prims.int` sont **euclidiens** dans F* mais tronqués dans le F# extrait ; ne jamais appeler `v`
  dans du code exécuté ; `FStar.Char.u32_of_char` échoue (`Error 395`).
- Custard **évalue les termes clos** à l'extraction : un test doit passer ses entrées par un effet (`MxUtil.blur`).
- Vérifier les modules F* dans l'ordre des dépendances (`Core` avant `App`) avec `--cache_checked_modules`.
- Avalonia 12.1.4 : `ScrollContentPresenter` retient le premier contenu : ne pas remplacer le contenu d'un `ScrollViewer`
  (voir `app/Ui/Runner.fs`). `TextBox.TextChanged` est asynchrone ; écouter `TextProperty`. Pas de `string`/`sprintf` sur des unions F#
  dans le code AOT (réflexion).
- Custard : `sprintf` avec un argument entier machine (`%y %i %l %L %uy…`) s'exécute en `failwith "Prims.admit"`, même flouté (Mx46) ; `Class.Printable.to_string` sur une liste ou un `Some` boucle à l'infini (Mx40) ; `RBMap.for_any` est faux
  dans ulib (Mx42) ; `String.lowercase/uppercase` ne touche que l'ASCII dans F* mais Unicode en .NET (Mx36).
- Plateformes : `Ui` ne dépend QUE d'Avalonia (noyau) ; le bureau (`Avalonia.Desktop`) est dans `UiDesktop`, la colle commune dans `Shell` ; les têtes
  (`HostStatic` bureau, `HostBrowser`, `HostAndroid`, `HostIOS`) sont minces. Un `open Avalonia.Controls` masque les cas `Button`/`Text` de `Node`.
  NativeAOT ne cross-compile pas entre OS : publier en JIT autonome pour les autres RID. L'installeur du SDK Android exige `USER` non vide
  (`XAIAD7009`) et l'acceptation de ses licences (`ACCEPT_ANDROID_LICENSES=1`, décision de l'utilisateur, jamais par défaut).
- `app/Extracted/{Extracted.fs,FStarCustard.fs,Extracted.fsproj}` sont **générés et non versionnés** (`.gitignore`) : après un clone, lancer `scripts/extract.sh` avant toute compilation ; la CI les produit dans son job `extract` (`docs/CI.md`).
- NativeAOT et F# : tous les projets de `app/` (sauf `HostDev`) se compilent avec `--reflectionfree` (`app/Directory.Build.props`) : sans lui le `ToString` généré des unions embarque le moteur `printf` de FSharp.Core (50 avertissements IL2xxx/IL3050). Pas de `Seq.init`/`Lazy`. Contrôle : `dotnet publish app/HostStatic -r linux-x64 -p:TrimmerSingleWarn=false` sans `warning IL` (`docs/AVERTISSEMENTS-AOT.md`).
- Shell : ne pas utiliser `pkill -f <motif>` quand le motif figure dans sa propre ligne de commande (cela tue le shell).

## 4. Tests : **uniquement du F\***, jamais de F# (décision de l'utilisateur)

- Les tests sont des programmes F* (`ftests/*.fst`, `docs/matrix/*.fst`), extraits par Custard (`--custard_main`) puis exécutés en JIT et en
  NativeAOT (`scripts/ftests.sh`). Aucun fichier F# n'est écrit pour tester. Les générateurs de texte (`scripts/gen_tmachine.py`,
  `scripts/gen_tulib.py`) produisent du F* commité ; ils ne contiennent aucune logique de test.
- Chaque entrée d'un test passe par un effet (`TUtil.blur`) : Custard évalue les termes clos ; `scripts/ftests.sh` refuse un `check true`
  résiduel (VIDE). Pas de `|| true` ni de condition vide : une opération dont aucun cas ne s'exécute fait échouer le test (`nonvacuous`).
- Pas de conversion « entier machine → `int` » à l'exécution (`v` n'a pas de réalisation F#) : les références travaillent en `int` et
  construisent les entiers machine par `uint_to_t` gardé. `/` et `%` seulement sur opérandes ≥ 0.
- Les fonctions à précondition sont appelées derrière une garde exécutée (`if i < length l then index l i`), F* en déduit la précondition.
- **Double oracle** (`ftests/ulib_cases.py` → `TUlib.fst`) : un prédicat total `c_N` est PROUVÉ par `assert_norm` (sémantique du normaliseur
  de F*) puis évalué à l'exécution sur les mêmes valeurs passées par `blur`. Les fonctions sans définition réductible (Seq, OrdSet, FiniteSet,
  Float, `to_string` des entiers machine, `Class.Ord.Raw`) sont marquées `nonorm` : les attendus viennent alors du contrat de l'interface.
- Un écart entre F* et le F# extrait n'est jamais « corrigé » dans le test : il devient un cas `docs/matrix/MxNN` (statut attendu dans
  `EXPECTED.tsv`, avec un lemme `sem` qui PROUVE la valeur de F*), et le test de la suite l'exclut avec un renvoi vers ce cas.
- Un module de test qui dépend d'un autre doit être vérifié **comme racine** dans l'ordre des dépendances (`ftests/ORDER`) : seule une racine
  voit son `.checked` écrit ; vérifier seulement `TMain` re-vérifie tout en mémoire et fait échouer l'extraction (`Error 317`).
- `--warn_error` suit la syntaxe OCaml : `-321-272` (et non `-321,-272`). Dans un commentaire F*, `F*)` ferme le commentaire.
