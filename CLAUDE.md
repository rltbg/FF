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
- `scripts/all.sh` (≈ 6 min) doit finir par « TOUT OK » avant de conclure ; mettre à jour `README.md`, `REPORT.md`, `docs/STATUT.md`
  quand un chiffre ou un comportement change.
- Pour chaque contournement : l'erreur exacte, la version, « inévitable » (défaut de la version) ou « évitable » (mon choix de code).
- Ne pas déposer de ticket ni publier quoi que ce soit en dehors de ce dépôt sans accord explicite de l'utilisateur.
- **Pas de GitHub Actions** (décision de l'utilisateur). Ne citer aucun numéro de ticket qu'on n'a pas lu soi-même.
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
- Shell : ne pas utiliser `pkill -f <motif>` quand le motif figure dans sa propre ligne de commande (cela tue le shell).
