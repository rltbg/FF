# Guide complet : écrire une application en F*, l'afficher avec Avalonia, la publier en NativeAOT

Ce guide regroupe tout ce qu'il faut savoir pour reprendre ce dépôt. Les autres documents :
[`REPORT.md`](../REPORT.md) (résultats détaillés de la 2e passe), [`STATUT.md`](STATUT.md) (fait / limité / impossible),
[`MATRICE-FSTAR.md`](MATRICE-FSTAR.md) (ce qui s'extrait), [`UPSTREAM-FSTAR.md`](UPSTREAM-FSTAR.md) et
[`FSTAR-char_code.md`](FSTAR-char_code.md) (défauts de F*), [`TODO-avalonia-upstream.md`](TODO-avalonia-upstream.md).

Versions : F* 2026.10.25 · .NET SDK 10.0.403 · Avalonia 12.1.4 · FSharp.Core 10.1.403.

## 1. L'idée

Architecture MVU (Elm) : **tout le code applicatif est en F\***, prouvé, puis extrait en F# ; une petite couche F# écrite à la main
(un interpréteur générique) transforme l'arbre de vue produit par F* en contrôles Avalonia.

```
 fst/Core.fst ─┐                                            ┌─ HostStatic (JIT / NativeAOT) : lié au cœur
 fst/App.fst  ─┴─ F* ── vérification ──► extraction F# ──► Extracted.dll ──┤
   Model, Msg, update, view_tree (donnée)                   └─ HostDev : recharge Extracted.dll à chaud
                                                                  │
                          app/Ui : Node ──► contrôles Avalonia ◄──┘  (seule couche qui connaît Avalonia)
```

- `update : model{inv} -> msg -> model{inv}` est pure et son invariant `inv` est prouvé.
- `view : model -> view_tree` renvoie de la **donnée** (colonne, ligne, texte, bouton portant son `msg`, champ, case, liste
  volumineuse…). Les `msg` et les tags de champs sont opaques pour l'hôte (`obj`) : il ne fabrique jamais un `msg` lui-même ;
  il appelle les fabriques exportées par F* (`msg_of_input`, `msg_of_select`, `msg_of_text`).
- Les gros volumes (100 000 lignes, texte de 1 Mo) restent **côté hôte** ; le modèle F* ne garde que des identifiants
  (`sel : option U32.t`) et un condensé (`digest`).

## 2. Mise en route

```
scripts/setup.sh     # installe F* et le SDK .NET dans .tools/ (versions épinglées, idempotent)
scripts/sources.sh   # code source de F* et d'Avalonia (mêmes versions) dans .tools/src/ : À LIRE avant d'écrire du code (voir CLAUDE.md)
scripts/all.sh       # passe complète depuis zéro, ≈ 7 min : doit finir par « TOUT OK »
```
Pré-requis système pour l'interface : Xvfb, `xdotool`, `x11-utils` (xwininfo, xprop), ImageMagick, `libfontconfig`.
(Dans le conteneur de test : `apt-get update` d'abord.)

| Script | Rôle |
|---|---|
| `extract.sh [full\|admit\|lax]` | vérifie `Core` puis `App` (dans cet ordre), extrait vers `app/Extracted/` |
| `build.sh` | compile tout, publie HostStatic et Tests en NativeAOT dans `out/` |
| `test.sh` | suite de tests en JIT puis en AOT |
| `ui_smoke.sh <cmd>` | parcours GUI complet sous Xvfb, oracles sur l'état du modèle |
| `hotreload.sh` | 5 scénarios de rechargement à chaud + assertion de déchargement |
| `mutate.sh` | 3 mutations du code F* : qui les détecte (F* ou les tests) |
| `matrix.sh`, `scale.sh` | matrice d'extraction F*, passage à l'échelle de `Seq`/`Map`/`Set`/`RBMap` |
| `repro_char_code.sh` | rejoue le défaut `char_code` et ses contournements |
| `loop.sh [mode]`, `loop_bench.sh` | un tour de boucle chronométré / six éditions par mode |
| `startup.sh`, `list_scale.sh` | démarrage et RSS ; limite de la liste non virtualisée |
| `watch_check.sh` | `dotnet watch` sur F# (réponse : redémarrage nécessaire) |

## 3. Écrire du F* qui s'extrait bien (règles issues des mesures)

1. **Rester dans le premier ordre** : listes, enregistrements, types algébriques, entiers machine (`U32`, `Int32`, `U8`…),
   `string`, `option`. Le détail est dans `MATRICE-FSTAR.md` (28 cas).
2. **Ne jamais appeler `v` dans le code qui s'exécute** (spécification seulement) ; comparer les entiers machine directement.
3. **`Prims.int`** devient `bigint` : correct mais lent ; pour le calcul, préférer les entiers machine. `/` et `%` de `Prims.int`
   sur des opérandes négatifs **ne sont pas ceux de F\*** (euclidiens dans F*, tronqués dans .NET).
4. **Négation d'un `int` non constant** : écrire `0 - a` (la négation unaire n'a pas de réalisation).
5. **Caractères** : `FStar.Char.int_of_char` / `char_of_int` ; pas `u32_of_char` (voir `FSTAR-char_code.md`). Un `char` est une
   unité UTF-16 ; `String.length` compte des unités UTF-16, pas des points de code.
6. **Hachage / encodage** : passer par `FStar.Bytes.utf8_encode` (octets), jamais par l'octet bas d'un `char`. Sa précondition
   (`maxlen s 2^30`) se prouve par une garde de taille (`lemma_len_maxlen`).
7. **Collections** : `Seq` = liste (index O(n)), `Map`/`Set` = chaînes de fermetures (`Set` déborde la pile vers 10⁶),
   `RBMap` = arbre équilibré. Pour de gros volumes, garder la donnée côté hôte.
8. **Spécifications** (`noextract`, lemmes, types `prop`) sont éliminées sans effort ; ne pas les mêler au code exécuté.
9. **Piège de test** : Custard évalue les termes clos à l'extraction. Un test d'extraction doit passer ses entrées par un effet
   (`MxUtil.blur`), sinon le code testé disparaît (`check true`) ; `matrix.sh` classe ce cas `VIDE`.
10. **Vérifier dans l'ordre des dépendances** (`Core` puis `App`), avec `--cache_checked_modules` ; l'extraction relit les `.checked`.

Commandes de base (équivalent de `scripts/extract.sh`) :
```
A="--odir _output --cache_dir _cache --already_cached Prims,FStar --warn_error -321"
fstar.exe $A --cache_checked_modules Core.fst && fstar.exe $A --cache_checked_modules App.fst
fstar.exe $A --codegen FSharp --custard_entry_module Core --custard_entry_module App App.fst -o Extracted.fs
```
Custard écrit `Extracted.fs`, `FStarCustard.fs` (bibliothèque d'exécution embarquée, 228 lignes utiles) et `Extracted.fsproj`.

## 4. Les modules F*

**`fst/Core.fst`** — FNV-1a 32 bits (constantes de draft-eastlake-fnv-21) : spécification sur liste d'octets, implémentation
sur `byte[]` **prouvée égale** (`lemma_fnv_bytes`), empreinte `fnv_utf8` d'une chaîne ; analyse décimale bornée
(`parse_nat` : `Some n` ⇔ que des chiffres ASCII et valeur ≤ 1000, **et** `n` est cette valeur) ; `name_ok` (1 à 20 unités
UTF-16, sans caractère de contrôle C0/DEL/C1).

**`fst/App.fst`** — modèle (`tab`, `counter : Int32`, `items` aux ids strictement décroissants, `draft`, `name`, `age`, `status`,
`sel`, `digest`), messages, `update`, `view`. Invariant `inv` : compteur dans [-1000, 1000], ids triés et < `next_id`,
`next_id` sans débordement, `sel < 100 000`. Lemmes d'application : `inc`/`dec`, `add` (+1), `remove` (élément absent),
`select` (sélection exacte, hors plage = inchangé), `hash_text` (condensé = (longueur, FNV-1a de l'UTF-8)), formulaire accepté
(nom valide, âge analysé, empreinte exacte).

Ce que les preuves **ne** couvrent **pas** (les tests les gardent) : les constantes FNV, la règle des caractères de contrôle.

## 5. L'hôte (F# écrit à la main)

- `app/Ui/Node.fs` : type `Node` (indépendant de F* et d'Avalonia), `CoreApi` (les 6 fonctions que l'hôte connaît du cœur),
  `BigData` (lignes et texte générés côté hôte).
- `app/Ui/Interp.fs` : interpréteur `Node → contrôles` **avec réconciliation** : l'arbre précédent est comparé position par
  position, les contrôles du même genre sont réutilisés (clics et focus ne sont pas perdus). Écoute synchrone de
  `TextBox.TextProperty` (l'événement `TextChanged` est asynchrone). `BigList`/`BigText` : `ListBox` virtualisée sur une `IList`
  dont les lignes sont calculées à la demande (`LazyRows`).
- `app/Ui/Runner.fs` : boucle MVU, `UiApp`, `Startup.run` (`UsePlatformDetect`, `MVU_SOFTWARE_RENDERING=1` force le rendu X11
  logiciel, `MVU_TRACE=<fichier>` journalise le modèle après chaque rendu). **Panneau hôte stable** dans le `ScrollViewer`
  (contournement d'un défaut d'Avalonia 12.1.4, voir `TODO-avalonia-upstream.md`).
- `app/HostStatic` : lie `Extracted` statiquement ; seule colle : `toNode` (arbre de vue F* → `Node`).
- `app/HostDev` : charge `Extracted.dll` dans un `AssemblyLoadContext` collectible, transfère le modèle par copie
  structurelle (`Reload.transplant`), surveille le fichier (sondage 200 ms : `FileSystemWatcher` ne voyait pas les réécritures
  de MSBuild dans le conteneur), mesure le déchargement. Réflexion : **dev uniquement, non AOT**.

## 6. Boucle de développement

Sauvegarde → vérification F* → extraction → `dotnet build` de `Extracted.dll` → l'hôte détecte le fichier, recharge, réaffiche.
Chiffres (`logs/loop_bench.log`, `logs/all.log`) : vérification 1,0–1,8 s (`--lax` / `--admit_smt_queries true`) ou 2,7–4,9 s
(complet) ; extraction ≈ 0,8 s ; `dotnet build` ≈ 5 s ; rechargement 10–35 ms ; **8 à 12 s de bout en bout**.
Ce qui exige un redémarrage ou une réinitialisation : un **changement de type du modèle** (le transfert échoue →
`model-RESET`, état remis à zéro). `dotnet watch` ne recharge pas F# (`Restart is needed to apply the changes.`) et, avec
`PublishAot=true`, il avertit que le projet ne supporte pas le Hot Reload. Le Hot Reload n'existe pas en NativeAOT.

## 7. Gros volumes : où mettre les données ?

| Option | Coût mesuré |
|---|---|
| 100 000 éléments **dans le modèle F\*** | construction 238–346 ms, 10,8 Mo ; `Toggle` 7–17 ms ; `view` 75–80 ms pour 200 008 nœuds. Afficher cela sans virtualisation est impraticable |
| Liste **non virtualisée** (un contrôle par élément) | 1 000 éléments : interface occupée 1,7 s (AOT) ; 5 000 : 6 s et 0,9 Go |
| **Liste virtualisée de 100 000 lignes côté hôte** (retenue) | +0 Mo de RSS, défilement jusqu'à la ligne 99 999 ; F* ne garde `sel` ; `Select` = 0,055 µs |
| `TextBox` avec 1 Mo | **+170 Mo de RSS** |
| **Visualiseur de lignes virtualisé** pour 1 Mo (retenu) | +6 Mo ; le texte entier n'est construit que pour le hachage |
| Hachage F* du texte de 1 022 080 octets | 3,0 à 3,6 ms (`fnv_utf8`), `HashText` 2,3 ms ; résultat vérifié contre une référence Python |

## 8. NativeAOT

`dotnet publish -c Release -r linux-x64` (`PublishAot=true` dans `HostStatic.fsproj` et `Tests.fsproj`, `IsAotCompatible` via
`app/Directory.Build.props`). Seuls warnings : `IL3053` et `IL2104` de FSharp.Core. Règles : pas de `sprintf`/`string` sur des
unions F# (réflexion), pas de réflexion dans `Ui`/`HostStatic` ; `HostDev` n'est pas publié en AOT.
Mesures (`logs/startup_bench_final.log`) : livrable **34,7 Mo** (binaire 20,7 + Skia 11,2 + HarfBuzz 2,8) ; fenêtre affichée en
**63 ms** (rendu logiciel) à **111 ms** (rendu par défaut) en médiane, contre 622 à 716 ms en JIT ; à froid 374 ms contre
1 192 ms ; RSS au repos 40 Mo (logiciel) à 109 Mo (défaut) contre 88 à 156 Mo en JIT. Sous Xvfb, le rendu par défaut passe par
Mesa (rastérisation logicielle) : **ces chiffres ne valent ni pour un GPU ni pour le mobile**.

## 9. Défauts connus et contournements (résumé)

| Quoi | Contournement | Détails |
|---|---|---|
| F* : `u32_of_char` (`Error 395`) | `int_of_char`, ou `assume val` + `@@custard_extern` | `FSTAR-char_code.md` |
| F* : `/`, `%` de `Prims.int` négatifs divergent | éviter, ou corriger le support F# | `UPSTREAM-FSTAR.md` §1 |
| F* : négation unaire, `Prims.abs` (`op_Tilde_Minus`) | `0 - a` | `UPSTREAM-FSTAR.md` §3 |
| Avalonia 12.1.4 : `ScrollContentPresenter` retient la 1re racine | panneau hôte stable | `TODO-avalonia-upstream.md` |
| `FileSystemWatcher` muet sur les réécritures MSBuild (conteneur) | sondage du fichier | `app/HostDev/Program.fs` |
| `dotnet watch` ne recharge pas F# | hôte `AssemblyLoadContext` | §6 |

## 10. Pour étendre

- **Ajouter un écran** : constructeur dans `tab`, branche dans `view`, éventuellement un nouveau cas de `view_tree` ; l'interpréteur
  (`Interp.fs`) et les deux conversions (`HostStatic/Program.fs: toNode`, `HostDev/Reload.fs: toNode`) doivent connaître le nouveau
  nœud (le compilateur F# signale les motifs incomplets). Ajouter un lemme et un test (`Tests/Program.fs`) pour la nouvelle règle.
- **Ajouter une garantie** : écrire le lemme dans `App.fst`, et si l'extraction n'est pas triviale, un cas dans `docs/matrix/`.
- **Ajouter un test GUI** : une étape dans `scripts/ui_smoke.sh` avec un `expect` sur le journal `MVU_TRACE`.
