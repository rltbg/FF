# F* : constats à remonter aux mainteneurs (non déposés)

Version testée : F* 2026.10.25 (commit `362e792`, dernier tag au 2026-10-26), backend F# « Custard », .NET 10.0.403.
**Aucun ticket F* n'a été recherché ni déposé** (la session n'a pas accès aux tickets de ce dépôt). Chaque constat ci-dessous
est reproductible par un cas de `docs/matrix/` (`scripts/matrix.sh`) ou de `docs/repro/` (`scripts/repro_char_code.sh`).
Les chemins de sources cités sont ceux du tag `v2026.10.25`.

| # | Constat | Gravité | Preuve | Correctif proposé |
|---|---|---|---|---|
| 1 | **Division et reste de `Prims.int` : F* est euclidien, le F# extrait tronque vers zéro** | **Haute** : un fait prouvé en F* est faux à l'exécution pour des opérandes négatifs | `Mx25` (RUN) | §1 |
| 2 | `u32_of_char` / `char_of_u32` inutilisables (`Error 395` sur `char_code`) | Moyenne | `Mx02`, `docs/FSTAR-char_code.md` | §2 |
| 3 | Négation unaire d'un `int` non constant et `Prims.abs` : `Error 395 Prims.op_Tilde_Minus` | Moyenne | `Mx26`, `Mx27` | §3 |
| 4 | Borne de `char_code` : `0xD7FF` exclu | Basse | `scripts/repro_char_code.sh` cas 5 | §4 |
| 5 | `char_of_u32` tronque silencieusement au-delà de `0xFFFF` | Basse (compromis UTF-16 documenté) | `FStarCustard.fs` | §5 |
| 6 | Documentation et tests en retard | Basse | §6 | §6 |
| 7 | **Bibliothèque de support F# ≠ spécification d'ulib** (`List.Tot.Base.splitAt`, `bool_of_compare`, `compare_of_bool`, `list_refb`) | **Haute** pour les trois premières : mêmes fonctions totales, autre valeur ou exception | `Mx30`, `Mx31`, `Mx32`, `Mx29` | §7 |
| 8 | `FStar.IO.print_uintN_hex_pad` imprime le préfixe `0x` (la référence OCaml : non) | Basse | `Mx34` | §8 |
| 9 | Chaînes : `lowercase`/`uppercase` Unicode vs ASCII, `split` de la chaîne vide, valeur de `compare`, longueur hors BMP | Moyenne (faits prouvés faux à l'exécution) | `Mx36` `Mx37` `Mx38` `Mx33` | §9 |
| 10 | `FStar.UInt.sub_mod` / `decr_mod` renvoient un négatif (conséquence du point 1 **dans ulib même**) | **Haute** | `Mx41` | §10 |
| 11 | Non réalisés en F# (`Error 395`) : `either`, `Float.bit_eq`/`to_string`, `UIntN.to_string_hex(_pad)`, `Int128.to_string`, `Int128.rotate_*` ; `Printf` avec entier machine : `failwith "Prims.admit"` à l'exécution | Moyenne | `Mx39` `Mx43` `Mx44` `Mx46`, `upstream_tests.sh`, `TMachine` | §11 |
| 12 | `Class.Printable.to_string` sur une liste ou un `Some` : **boucle infinie** à l'exécution (dictionnaire cyclique, avertissement de F* ignoré par Custard) | Haute (silencieux : s'arrête de répondre) | `Mx40` | §12 |
| 13 | **Défaut d'ulib seul** : `FStar.RBMap.for_any` appelle `for_all` dans les sous-arbres | Moyenne | `Mx42` | §13 |
| 14 | Paramètre de type fantôme dans une abréviation : F# refuse (`FS0035`) en extraction de bibliothèque | Basse | `docs/repro/PhantomTypeParam.fst` | §14 |

## 1. `/` et `%` sur `Prims.int` : F* euclidien, F# tronqué

**Ce que dit F*.** `ulib/Prims.fst` : « Both the modulus and division operations are Euclidean and are mapped to the
corresponding theory symbols in the SMT encoding » ; `( % )` : « Euclidean modulus » ; `( / )` : « Euclidean division ».
Vérifié avec `fstar.exe` (`assert_norm`) : `(-7)/2 = -4`, `(-7)%3 = 2`, `7/(-3) = -2`, `7%(-3) = 1`, `(-7)/(-3) = 3`,
`(-7)%(-3) = 2` sont **prouvés** ; `(-7)/2 = -3` et `(-7)%3 = -1` sont **rejetés**.

**Ce que fait le F# extrait.** `FStarCustard.fs` : `let op_Slash (x : bigint) (y : bigint) = x / y` et
`let op_Percent … = x % y`. `System.Numerics.BigInteger` tronque vers zéro : `-7/2 = -3`, `-7 % 3 = -1`
(mesuré : `dotnet fsi`, `BigInteger natif : -7/2 = -3, -7 % 3 = -1`).

**Reproduction** : `docs/matrix/Mx25_PrimsIntDivNeg.fst` ; le lemme `sem` (F*) prouve les valeurs euclidiennes et le test
`check (m7 / 2 = -4)` échoue à l'exécution (`FAIL`).

**Ailleurs dans le code de F*.** Le commentaire de `PrintFSharp.fst` (section « Prims.int ») affirme « The division and
remainder round toward zero, which is what Prims specifies and what System.Numerics.BigInteger does » : c'est faux pour
la première moitié (Prims spécifie l'euclidien).

**Entiers machine :** pas concerné. `FStar.Int32.div/rem` : F* prouve la troncature (`-7/2 = -3`, `-7 rem 3 = -1`) et
le F# calcule pareil (`Mx28`, OK).

**Correctif proposé** (testé hors de F* : `dotnet fsi`, 10 100 couples dans [-50, 50]², invariant `x = y*q + r`,
`0 <= r < |y|`, plus les valeurs ci-dessus) pour `Prims.op_Percent` et `Prims.op_Slash` du support F# :
```fsharp
let op_Percent (x : bigint) (y : bigint) : bigint =
  let r = x % y
  if r.Sign < 0 then r + bigint.Abs y else r
let op_Slash (x : bigint) (y : bigint) : bigint = (x - op_Percent x y) / y
```
Non appliqué dans F* (pas de reconstruction du compilateur).

**Impact sur ce dépôt :** aucun (le code livré ne divise pas d'entiers négatifs ; le `% 256` de la 1re passe a disparu).
Tout programme qui prouve quelque chose avec `/` ou `%` sur des opérandes pouvant être négatifs est concerné.
**Impact dans ulib elle-même** (3e passe, §10) : `FStar.UInt.sub_mod` et `decr_mod` sont définis par `(a - b) % pow2 n` et renvoient une valeur négative hors de `uint_t n`.

## 2. `FStar.Char.u32_of_char` : `Error 395`

Détail complet : `docs/FSTAR-char_code.md`. Résumé : `reject_realized_types` (`PrintFSharp.fst`) rejette le type
`FStar.Char.char_code` (déclaré dans un module réalisé en OCaml, absent de `builtin_type`) ; `--custard_extern_type` n'y
change rien ; contournement testé : déclaration locale `assume val` + `@@custard_extern "FStar_Char.u32_of_char"`.
Correctif proposé : `| "FStar.Char.char_code" -> Some "uint32"` dans `builtin_type` (non vérifié).

## 3. Négation unaire et `Prims.abs`

```
* Error 395:
  - Custard: Prims.op_Tilde_Minus has no F* definition and no F# realization.
```
`ulib/Prims.fst` : `val ( ~- ) : int -> Tot int` (« `[-x]` is notation for `[~-x]` »), donc `-a` pour un `int` **non
constant** est `Prims.op_Tilde_Minus`. `supported_realizations` (`PrintFSharp.fst`) ne contient que `Prims.op_Minus` et
`Prims.op_Minus_Minus` ; `FStarCustard.fs` définit `op_Minus_Minus (x) = -x`. Il manque la correspondance
`Prims.op_Tilde_Minus -> Prims.op_Minus_Minus`. `Prims.abs` est défini en F* par `if x >= 0 then x else -x` : même erreur.
Les littéraux négatifs constants (`-1000`) ne sont pas touchés. Reproduction : `Mx26_UnaryMinus`, `Mx27_PrimsAbs`.
Contournement : écrire `0 - a`.

## 4. Borne de `char_code`

`ulib/FStar.Char.fsti` : `n < 0xd7ff \/ (n >= 0xe000 /\ n <= 0x10ffff)`. `0xD7FF` est un scalaire Unicode valide ; la
spec le rejette (`let x : char_code = 0xD7FFul` → `Failed to prove: Prims.l_False`). Le commentaire voisin dit « not
between 0xd800 and 0xe000 ». Probable erreur d'un cran (`<=` attendu). À confirmer.

## 5. `char_of_u32` au-delà du BMP

`FStarCustard.fs` : `let char_of_u32 (u : uint32) : char = char (int u)`. Pour `u > 0xFFFF` la valeur est tronquée
(`0x1F642` → `0xF642`). `custard.md` assume ce compromis UTF-16 ; la spec F* de `char_of_u32` ne le prévoit pas. À
documenter dans la spec réalisée, ou à rejeter à l'extraction.

## 6. Documentation et tests

- `doc/ref/custard.md` §122.15 : « `FS_TESTS` is 24 programs » ; `tests/custard/Makefile` en liste **28** (`FS_TESTS +=`).
- Aucun programme de la suite F# n'exerce `u32_of_char`/`char_of_u32` ; un seul (`LitStr`) touche `Char`/`String` (une
  référence). `supported_realizations` liste ces fonctions sans qu'un test F# les compile, ce qui explique que le point 2 soit passé
  inaperçu. Un test `FsChar` (Char/String/Bytes) l'aurait détecté ; de même pour la négation (point 3) et la division
  négative (point 1).
- Messages d'erreur (point 2) : « realized by hand-written OCaml » pour un simple raffinement d'entier ;
  « Extract with --codegen OCaml » ne dit pas que le contournement existe.
- Piège de méthode, pas un défaut : Custard **évalue les termes clos à l'extraction**. `check (v (u32_of_char 'A') = 65)`
  devient `check true` et l'`Error 395` n'apparaît pas ; un test d'extraction doit passer ses entrées par un effet
  (`docs/matrix/MxUtil.fst`, `blur`). Cela mérite une ligne dans la documentation du backend F#.

## 7. Bibliothèque de support F# ≠ spécification d'ulib (`FStar.List.Tot.Base`)

Le texte de la bibliothèque de support est dans `src/custard/FStarC.Custard.PrintFSharp.fst` (lignes ≈ 1930–2070, recopié en
`FStarCustard.fs`). Quatre fonctions de `FStar.List.Tot.Base` y sont réalisées autrement que leur définition F* :

| Fonction | F* (`ulib/FStar.List.Tot.Base.fst`) | F# de support | Cas |
|---|---|---|---|
| `splitAt n l` | **totale** : `(l, [])` si `n > length l` | `List.splitAt (int n) l` : **lève `InvalidOperationException`** | `Mx30` (RUN) |
| `bool_of_compare f x y` | `f x y < 0` | `f x y > 0I` : **signe inversé** | `Mx31` (RUN) |
| `compare_of_bool rel x y` | `-1` si `rel x y`, `0` si `x = y`, `1` sinon | `1I` / `0I` / `-1I` : **signes inversés** | `Mx32` (RUN) |
| `list_refb` | `#p` (prédicat booléen) argument implicite non effacé | `list_refb (l : 'a list)` : un seul argument, le **F# généré ne compile pas** (FS0003) | `Mx29` (BUILD) |

Chaque cas contient un lemme `sem` qui **prouve** la valeur de F* par `assert_norm` ; l'exécution du F# extrait la contredit.
Correctifs proposés (non appliqués) :
```fsharp
let splitAt (n : bigint) (l : 'a list) = List.splitAt (min (int n) (List.length l)) l
let bool_of_compare (f : 'a -> 'a -> bigint) (x : 'a) (y : 'a) : bool = f x y < 0I
let compare_of_bool (r : 'a -> 'a -> bool) (x : 'a) (y : 'a) : bigint = if r x y then -1I elif x = y then 0I else 1I
let list_refb (_p : 'a -> bool) (l : 'a list) : 'a list = l
```
`sortWith` n'est pas touchée (la réalisation F# trie correctement ; la suite F* le vérifie contre le tri de référence).

## 8. `FStar.IO.print_uintN_hex_pad`

`ulib/FStar.IO-ocaml.fst` : `print_uint8_hex_pad x = print_string (U8.to_string_hex_pad x)` ; `FStar.UInt8.fsti` : « left-padded with zeroes,
**no leading 0x** » ; `tests/machine_integers/TestPrint.out.expected` : `00 0f ff`. Le F# de support écrit `hexpad n v = "0x" + …` :
`0x00 0x0f 0xff`. `Mx34` compare la sortie à `Mx34_PrintHexPad.expected`. Correctif : retirer `"0x" +` de `hexpad` (ce qui ne change pas `print_uintN`,
qui utilise `hex`).

## 9. Chaînes et caractères

Le normaliseur de F* (réalisation OCaml native) est la **référence** : `assert_norm` prouve les faits ci-dessous, le F# extrait les contredit.
- `String.lowercase "ÉA" = "Éa"` et `uppercase "éa" = "éA"` : F* ne traite que l'ASCII ; `ToLowerInvariant`/`ToUpperInvariant` convertissent tout Unicode (`Mx36`).
- `String.split ['/'] "" = []` dans F* ; `String.Split` de .NET renvoie `[""]` (`Mx37`). Le reste de `split` concorde (« a/ », « / », « a//b », plusieurs séparateurs).
- `String.compare "a" "c" = -1` dans F* (la doc ne promet que le signe) ; `CompareOrdinal` renvoie la différence des unités, `-2` (`Mx38`).
- `String.length` d'un littéral hors BMP : F* compte des points de code (1 pour U+1F642), .NET des unités UTF-16 (2) (`Mx33`) ; cf. §5.
- `Char.lowercase/uppercase` ne sont pas réductibles par le normaliseur : aucune référence, seul le contrat (« variante minuscule ») les décrit.

## 10. `FStar.UInt.sub_mod` et `decr_mod`

Définis par `(a - b) % pow2 n` (`ulib/FStar.UInt.fst`). F* prouve `sub_mod #8 5 10 = 251` ; le F# renvoie `-5` (reste tronqué de `BigInteger`, point 1) :
`decr_mod #8 0 = -1`, `sub_mod #64 0 1 = -1`. Une valeur négative n'appartient pas à `uint_t n` : tout ce qui est prouvé sur ces fonctions est faux à
l'exécution. (`FStar.UInt8..64`, entiers .NET natifs, ne sont pas concernés ; `Mx41`.) Le correctif du point 1 règle aussi ce cas.

## 11. Non réalisé en F# (`Error 395`) ou erroné à l'exécution

| Élément | Constat | Où observé |
|---|---|---|
| `FStar.Pervasives.either` (`Inl`/`Inr`) | `the type FStar.Pervasives.either is realized by hand-written OCaml and has no F# realization` | `Mx39` ; ulib : `Class.Printable`, `Universe`… |
| `Float32/64.bit_eq`, `Float32/64.to_string` | `has no F* definition and no F# realization` (alors que `Builtins.fst` dit que `bit_eq` « stays a call into the support library ») | `Mx43`, `Mx44` |
| `UInt8/16/32/64.to_string_hex`, `to_string_hex_pad` | idem ; `tests/machine_integers/TestPrint` ne s'extrait pas en F# | `upstream_tests.sh` |
| `Int128.to_string`, `Int128.rotate_left/right` | idem (`Builtins.fst` exclut explicitement les rotations à 128 bits) | `TMachine` (`gen_tmachine.py`, `BLOCKED`) |
| `FStar.Printf.sprintf` avec `%y %i %l %L %uy %us %ul %uL` | **s'exécute en `failwith "Prims.admit"`** : `string_of_arg` est déroulé sur `FStar.Int8.to_string`, dont la définition F* est `admit ()`, au lieu de la réalisation .NET. `%d %s %b %c %%` fonctionnent | `Mx46` |
| `FStar.Char.char_code`, `Prims.op_Tilde_Minus` | points 2 et 3 ci-dessus ; `tests/machine_integers/TestChar` et `TestShift` ne s'extraient pas | `upstream_tests.sh` |

Les tests de la branche F# de l'amont (`FS_TESTS` de `tests/custard/Makefile`, 28 programmes) passent tous ; les trois programmes `TestChar`, `TestPrint`,
`TestShift` de `tests/machine_integers/` n'y sont pas inscrits et auraient détecté ces trous.

## 12. `FStar.Class.Printable.to_string` sur une liste ou une option non vide : boucle infinie

`Pr.to_string [1; 2; 3]` : F* émet « fuel exhausted during typeclass resolution. This usually indicates a loop in your instances » (l'instance
`printable_ref` s'applique à tout type `x:a{p x}`), puis le normaliseur prouve pourtant `= "[1; 2; 3]"`. Custard compile la projection du
dictionnaire cyclique en `let rec f tmp = f tmp` (voir le F# généré : `fStar_Class_Printable___proj__Mkprintable__item__to_string__int`) ; le programme
**ne répond plus** dès qu'il imprime un élément (`Mx40`, délai de 30 s). Sur un entier seul, tout va bien. Piste : traiter un avertissement de résolution de
classes de types épuisée comme une erreur à l'extraction.

## 13. Défaut d'ulib : `FStar.RBMap.for_any`

`ulib/FStar.RBMap.fst` : `p x vx || for_all p a && for_all p b` au lieu de `for_any` dans les sous-arbres. Résultat `false` quand seul un nœud non racine
satisfait `p` (`Mx42` ; le normaliseur de F* donne la même valeur fausse). `FStar.RBSet.for_any` est correct.

## 14. Paramètre de type fantôme

`type tagged (a:Type) = int`, extrait en bibliothèque (`--custard_entry_module`), devient `type …_tagged<'a> = bigint` que F# 10 refuse
(`error FS0035 … Type abbreviations must use all declared type parameters`). Sept modules d'ulib sont touchés (`FStar.Fin`, `Functions`, `Injection`,
`IntegerIntervals`, `Seq.Permutation`, `Sequence.Permutation`, `Tactics.CanonCommSwaps`). Sous `--custard_main` le type est inliné et le défaut ne se voit
pas : `docs/repro/PhantomTypeParam.fst`, `scripts/repro_phantom.sh`. Correctif : n'émettre que les paramètres utilisés, ou `[<Measure>]`/`obj` pour les inutilisés.

## Pour déposer plus tard
1. Chercher les doublons dans les tickets de `FStarLang/FStar` (non fait).
2. Joindre le cas de `docs/matrix/` ou `docs/repro/` correspondant, la version, et la sortie de `scripts/matrix.sh`.
3. Commencer par les points 1 et 7 : ce sont ceux qui rendent faux, sans bruit, un résultat prouvé (`/` `%`, `splitAt`, `compare_of_bool`, `bool_of_compare`).
