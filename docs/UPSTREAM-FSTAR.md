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

## Pour déposer plus tard
1. Chercher les doublons dans les tickets de `FStarLang/FStar` (non fait).
2. Joindre le cas de `docs/matrix/` ou `docs/repro/` correspondant, la version, et la sortie de `scripts/matrix.sh`.
3. Commencer par le point 1 : c'est le seul qui rend faux un résultat prouvé.
