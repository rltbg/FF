# F* → F# : `FStar.Char.u32_of_char` inutilisable (`Error 395`)

Version : F* 2026.10.25 (commit `362e792`, dernier tag au 2026-10-26), backend F# « Custard ».
Rejouer tous les cas ci-dessous : `scripts/repro_char_code.sh` (fichiers dans `docs/repro/`).

## 1. Symptôme

```fstar
let f (c:FStar.Char.char) : FStar.UInt32.t = FStar.Char.u32_of_char c
```
Le module se **vérifie** sans problème. L'extraction `--codegen FSharp` échoue :

```
* Error 395:
  - Custard: the type FStar.Char.char_code is realized by hand-written OCaml and
    has no F# realization.
  - Its declaration says what shape the type has, but not what it is: the
    definition is in ulib/ml, and there is no F# counterpart of that library
    (section 122.9).
  - Extract this program with --codegen OCaml, or keep it to the fragment the C
    backend compiles.
```
Les messages sont trompeurs : `FStar.Char.char_code` n'est pas une bibliothèque OCaml, c'est
`type char_code = n:U32.t{U32.v n < 0xd7ff \/ (U32.v n >= 0xe000 /\ U32.v n <= 0x10ffff)}` (`ulib/FStar.Char.fsti`),
un simple raffinement de `uint32`. Il en va de même pour `FStar.Char.char_of_u32`, qui prend un `char_code`.

## 2. Cause (dans le code de F*, tag v2026.10.25)

1. `FStar.Char` est un module « réalisé par du OCaml écrit à la main » (`Rule_realized`,
   `src/custard/FStarC.Custard.Builtins.fsti`). Custard marque donc **tous** les types qu'il déclare du drapeau `Realized`
   (`FStarC.Custard.Syntax.fsti`) : forme conservée, aucune déclaration émise.
2. `src/custard/FStarC.Custard.PrintFSharp.fst`, `builtin_type` : liste blanche des types que .NET possède déjà.
   On y trouve `"FStar.Char.char" -> "char"` mais **pas** `"FStar.Char.char_code"`.
3. Même fichier, `reject_realized_types` (≈ ligne 1455) : tout `DType` marqué `Realized` qui n'est ni un `builtin_type`
   ni un tuple déclenche `Error_CustardNoFSharpRealization` (Error 395).
4. Les **fonctions** `u32_of_char`, `char_of_u32`, `int_of_char`… sont bien réalisées : elles figurent dans
   `supported_realizations` (même fichier, ≈ ligne 1305) et dans la bibliothèque générée `FStarCustard.fs`
   (`FStar_Char.u32_of_char (c:char) : uint32 = uint32 (int c)`). Il manque seulement le **type** dans leur signature.

La documentation (`doc/ref/custard.md` §122.17) dit pourtant que `FStar.Char` fait partie des modules « mirrored ».

## 3. Ce qui ne marche pas

| Tentative | Résultat |
|---|---|
| `--custard_extern_type FStar.Char.char_code=uint32` | **Sans effet** : `Error 395` identique. L'option est faite pour « un type d'une bibliothèque qu'on ne possède pas » (aide de `fstar.exe`), mais `reject_realized_types` ne la consulte pas. |
| `[@@custard_extern]` sur `char_code` | Impossible : la déclaration est dans la bibliothèque. |
| `--codegen OCaml` | Contourne, mais ce n'est pas la cible visée. |

## 4. Contournements (les deux sont testés par `scripts/repro_char_code.sh`)

**A. `FStar.Char.int_of_char`** (retenu dans `fst/Core.fst`) : réalisé, renvoie un `nat` (donc `bigint` en F#).
```fstar
let is_digit (c:FStar.Char.char) : bool = let n = FStar.Char.int_of_char c in 48 <= n && n <= 57
```
Aucun axiome ajouté de notre côté. Inconvénient : arithmétique en `bigint`.

**B. Déclaration locale de la fonction, avec sa cible .NET** (arithmétique native `uint32`) :
```fstar
[@@custard_extern "FStar_Char.u32_of_char"]
assume val u32_of_char (c:C.char) : Tot (n:U32.t{n == C.u32_of_char c})
```
Le type de retour est `U32.t` et non `char_code` : Custard ne rencontre jamais le type réalisé. Extrait, compilé et exécuté
(`docs/repro/CharCodeWorkaround.fst`). Inconvénients : un `assume val` est un **axiome** (on fait confiance à la
réalisation de `FStarCustard.fs`), et on perd l'information « n est un `char_code` » (la borne du raffinement).

## 5. Correctif proposé pour F* (non appliqué, non testé)

Dans `PrintFSharp.fst`, `builtin_type` :
```fstar
  | "FStar.Char.char_code" -> Some "uint32"
```
Hypothèse : `char_code` est un raffinement de `uint32`, et la réalisation `u32_of_char`/`char_of_u32` de `FStarCustard.fs`
manipule déjà des `uint32`. **Je n'ai pas reconstruit F*** (amorçage OCaml long) : le correctif n'est pas vérifié.

## 6. Constats voisins (à confirmer avec les mainteneurs)

- **Borne de `char_code`** : la spec écrit `n < 0xd7ff`, ce qui exclut `0xD7FF`, scalaire Unicode valide (le commentaire
  de la spec parle de « not between 0xd800 and 0xe000 »). Vérifié : `let x : char_code = 0xD7FFul` est rejeté par F*
  (`Failed to prove: Prims.l_False`). Probable erreur d'un cran (`<=` attendu).
- **`char_of_u32` au-delà du BMP** : réalisé par `char (int u)` (`FStarCustard.fs`) ; pour `u > 0xFFFF` la valeur est
  tronquée silencieusement, alors que la spec renvoie le caractère. `custard.md` (§122.9/`builtin_type`) assume ce
  compromis UTF-16 (« agree on the BMP and part company above it »), mais le troncage n'est pas signalé à l'appelant.
- **Message d'erreur** : il désigne `char_code` comme « réalisé par du OCaml écrit à la main », ce qui induit en erreur
  sur un type qui est un raffinement d'entier.

## 7. Statut

Constaté et reproduit avec F* 2026.10.25. **Aucun ticket F* recherché ni déposé.** Si F* corrige un jour le défaut,
`scripts/repro_char_code.sh` le signale (cas 1 : « EXTRACTION RÉUSSIE ») : on pourra alors retirer le contournement.
