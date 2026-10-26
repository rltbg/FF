# Matrice d'extraction F* → F# : ce qui marche, ce qui casse, ce qui diverge

F* 2026.10.25, backend Custard, .NET 10.0.403. **Rejouer :** `scripts/matrix.sh` (résultats attendus dans
`docs/matrix/EXPECTED.tsv`, comparés automatiquement) et `scripts/scale.sh` (passage à l'échelle).
Chaque cas de `docs/matrix/` est vérifié par F*, extrait, compilé, **exécuté**, et doit afficher `OK`.

## 1. Résultats (28 cas : 24 OK, 3 échecs d'extraction, 1 divergence à l'exécution)

| Cas | Fonctionnalité | Résultat | Remarque |
|---|---|---|---|
| Mx01 | `FStar.Char` : `lowercase`, `uppercase`, `int_of_char` | OK | |
| Mx02 | `FStar.Char.u32_of_char` | **EXTRACT** | `Error 395` sur `char_code` : `docs/FSTAR-char_code.md` |
| Mx03 | `FStar.Char.char_of_int` | OK | réalisé directement (sa signature ne mentionne pas `char_code`) |
| Mx04 | `FStar.String` : `make`, `length`, `concat`, `^`, `split`, `upper/lowercase`, `index_of`, `list_of_string`, `string_of_list`, `string_of_char` | OK | `length` compte des unités UTF-16 |
| Mx05 | `FStar.String` : `get`, `substring`, `compare` | OK | |
| Mx06 | `FStar.List.Tot` : `map`, `filter`, `fold_left`, `rev`, `@`, `length`, `nth`, `mem`, `assoc`, `for_all`, `existsb`, `find`, `partition`, `split` | OK | listes F# natives |
| Mx07 | `List.Tot.sortWith` | OK | |
| Mx08 | `FStar.Option` : `isSome`, `mapTot` ; `option` | OK | `option` d'F# natif |
| Mx09 | `FStar.Seq` : `empty`, `cons`, `length` | OK | **compilé comme une `list<'a>` F#** (modèle de `FStar.Seq.Base`) |
| Mx10 | `FStar.Set` : `empty`, `add`, `mem` | OK | **chaîne de fermetures** (modèle fonctionnel) |
| Mx11 | `FStar.Map` : `const`, `upd`, `sel` | OK | **chaîne de fermetures** |
| Mx12 | `FStar.RBMap` : `empty`, `add`, `lookup`, `mem` | OK | arbre rouge-noir écrit en F* pur, classe de type `ord` |
| Mx13 | `FStar.OrdSet` : `singleton`, `union`, `mem` | OK | |
| Mx14 | `FStar.UInt64` : `add_mod`, `mul_mod`, `shift_left`, `logxor` | OK | `uint64` natif |
| Mx15 | `FStar.Int64` : `add`, `sub`, `gt`, `lt` | OK | `int64` natif |
| Mx16 | `FStar.Int.Cast` : conversions entre largeurs | OK | |
| Mx17 | `FStar.UInt128` : `add`, conversions | OK | `System.UInt128` |
| Mx18 | `FStar.Printf.sprintf "%d-%s"` | OK | |
| Mx19 | `Prims.int` : `pow2`, `*`, `/`, `%`, opérandes positifs | OK | `bigint` |
| Mx20 | `FStar.Bytes` : `utf8_encode`, `len`, `get`, `append`, `hex_of_bytes` | OK | `byte[]` |
| Mx21 | `FStar.Ghost.erased` | OK | effacé à l'extraction |
| Mx22 | types paramétrés, récursion mutuelle | OK | |
| Mx23 | `FStar.All.try_with`, `failwith` | OK | |
| Mx24 | `FStar.Float64` : `of_int`, `add`, `mul`, `ieee_eq` | OK | `float` |
| Mx25 | `Prims.int` `/` et `%` sur opérandes **négatifs** | **RUN** | F* prouve `(-7)/2 = -4`, le F# calcule `-3` : `docs/UPSTREAM-FSTAR.md` §1 |
| Mx26 | négation unaire d'un `int` non constant | **EXTRACT** | `Prims.op_Tilde_Minus` sans réalisation : §3 |
| Mx27 | `Prims.abs` | **EXTRACT** | même cause |
| Mx28 | `FStar.Int32.div/rem`, opérandes négatifs | OK | F* prouve la troncature, .NET aussi : pas de divergence |

## 2. Règles pratiques qui en découlent

- **Dans le code extrait, ne jamais utiliser `v` (fonction de spécification).** `FStar.UInt32.v x` donne
  `Error 395 … has no F* definition and no F# realization` : comparer directement les entiers machine (`=`, `lt`, `lte`).
- Écrire `0 - a` plutôt que `-a` pour un `int` non constant ; éviter `Prims.abs`. Les littéraux négatifs sont corrects.
- Ne pas faire confiance à `/` et `%` de `Prims.int` pour des opérandes qui peuvent être négatifs (divergence F*/.NET) ;
  les entiers machine sont fidèles.
- Pour `Char`, utiliser `int_of_char` / `char_of_int` (ou le contournement documenté), pas `u32_of_char` / `char_of_u32`.
- `FStar.Seq` est une liste : `index` et `length` sont **O(n)**. `FStar.Set` et `FStar.Map` sont des chaînes de
  fermetures. Pour des collections de taille, préférer des listes explicites, `RBMap`, ou garder la donnée côté hôte.
- Précondition des fonctions de bibliothèque (`Bytes.append`, `shift_left`, `Int64.add`…) : la prouver avec une
  garde (`if … then`) quand la valeur vient de l'extérieur.

## 3. Piège de méthode : Custard évalue les termes clos

Custard normalise à l'extraction les termes sans variable libre : `check (FStar.UInt32.v (u32_of_char 'A') = 65)` devient
`check true` dans le F# généré, **sans erreur**, et le code qu'on voulait tester disparaît. Mes premiers cas de la matrice
affichaient ainsi des « OK » trompeurs (Mx02 et Mx03). Les cas actuels passent leurs entrées par `MxUtil.blur`
(lecture d'une référence mutable : un effet, donc non évaluable). `scripts/matrix.sh` classe `VIDE` un cas dont un `check` est devenu
`true` dans le F# généré.

## 4. Passage à l'échelle (`scripts/scale.sh`, `logs/scale.tsv`)

Construction de N éléments puis requête **au pire cas** (élément le plus ancien) ; temps total du processus, démarrage .NET
compris (≈ 50 ms).

| Structure | N = 1 000 | 10 000 | 100 000 | 1 000 000 |
|---|---|---|---|---|
| `Seq` (liste), `index` du dernier | 70 ms | 69 ms | 71 ms | 439 ms |
| `Map` (fermetures), `sel` du plus ancien | 47 ms | 50 ms | 65 ms | 910 ms |
| `Set` (fermetures), `mem` du plus ancien | 56 ms | 46 ms | 81 ms | **plantage : `Stack overflow`** (≈ 174 000 appels imbriqués répétés) |
| `RBMap` (arbre), `lookup` | 73 ms | 124 ms | 452 ms | 3 626 ms |

`Set` est le seul à dépasser la pile ; il tient 100 000 éléments mais pas 1 million. Le modèle `App` complet avec 100 000
éléments : voir `docs/GUIDE.md` §7.
