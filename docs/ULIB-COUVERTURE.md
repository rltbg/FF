# Test de « toutes les fonctions F* disponibles » : méthode, couverture, écarts

Objectif posé : évaluer, par des tests **écrits en F\*** (aucun test en F#), tout ce que la chaîne F* → Custard → F# peut faire de la bibliothèque
standard, pour y trouver ce qui pose problème. Ce document dit **ce qui est testé, comment, avec quelle mesure de couverture, et ce que cela a trouvé**.
Les tables chiffrées sont générées par les scripts (jamais saisies à la main) : voir les liens.

## 1. Cinq niveaux de test

| Niveau | Quoi | Où | Oracle |
|---|---|---|---|
| A. Surface **réalisée** (écrite à la main dans la bibliothèque de support F#) | les 187 entrées de `supported_realizations` : `Prims`, `FStar.List.Tot.Base`, `FStar.List`, `FStar.String`, `FStar.Char`, `FStar.Bytes`, `FStar.IO`, `FStar.All`, impressions d'entiers | `ftests/TList.fst`, `TString.fst`, `TBytes.fst`, `TIO.fst` ; `docs/matrix/` pour les écarts | contrat des interfaces (`.fsti`), valeurs écrites à la main, propriétés (inverses, longueurs, permutations), références indépendantes écrites en `int` |
| B. **Entiers machine** | `UInt8/16/32/64/128`, `Int8/16/32/64/128` : `add`/`sub`/`mul` (+ `_mod`, `_underspec`), `div`, `rem`, `logand/or/xor/not`, décalages, `shift_arithmetic_right`, rotations, comparaisons, masques, `to_string`, `zero/one`, **tous les casts** de `FStar.Int.Cast` et `Cast.Full` (58) | `ftests/TMachineLib.fst` (harnais) + `TMachine.fst` (généré par `scripts/gen_tmachine.py`) | oracle écrit en `int` (opérandes ≥ 0, complément à deux reconstruit à la main) ; opérandes aux bornes + aléatoires ; chaque opération doit exécuter au moins un cas (sinon échec) |
| C. Modules d'ulib **compilés depuis leur définition F\*** | `Option`, `Order`, `Seq.Base/Properties`, `Set`, `Map`, `PartialMap`, `FunctionalQueue`, `OrdSet`, `OrdMap`, `FiniteSet/Map`, `RBSet/RBMap`, `UInt`, `BitVector`, `List.Pure.Base`, `Sequence.Base/Util`, `Class.Printable/Eq/Add/TotalOrder/Ord.Raw`, `Printf`, `Float32/64` | `ftests/ulib_cases.py` → `TUlib.fst` (généré par `scripts/gen_tulib.py`), `TFloat.fst` | **double oracle** : prédicat prouvé par `assert_norm` (sémantique de F*) *et* évalué par le F# extrait ; `nonorm` quand la fonction n'a pas de définition réductible |
| D. **Tests amont** de F* exécutés par le backend F# | les 28 programmes `FS_TESTS` de `tests/custard/` + 8 de `tests/machine_integers/` | `scripts/upstream_tests.sh`, attendu : `docs/upstream/EXPECTED.tsv` | code de retour 0 de l'exécutable |
| E. **Balayage** de tout ulib | 221 modules extraits comme bibliothèque (`--custard_entry_module`) puis compilés en F# | `scripts/ulib_sweep.sh` → `docs/ULIB-SWEEP.tsv` | l'extraction et la compilation réussissent-elles ? |

Résultats générés : [`COUVERTURE-REALISATIONS.md`](COUVERTURE-REALISATIONS.md) (niveau A, mesure exacte par nom de réalisation),
[`COUVERTURE-ULIB.md`](COUVERTURE-ULIB.md) (niveaux C et E : causes d'échec d'extraction, définitions atteintes module par module),
[`ULIB-SWEEP.tsv`](ULIB-SWEEP.tsv) (résultat brut du balayage).

## 2. Mesures de couverture et leurs limites (honnêteté)

- **Niveau A** : la suite doit référencer chaque réalisation par son nom F# dans le F# généré (`scripts/coverage_realizations.py`). Résultat : toute
  réalisation est soit exercée, soit déclarée bloquée avec sa raison ; le script échoue sinon. Les opérateurs de `Prims` (compilés en natif) sont
  comptés « natifs » sur la foi de `TString.test_prims` (liste écrite dans le script, vérifiée à la main).
- **Niveau B** : couverture par construction (largeur × opération), vérifiée par `nonvacuous` ; c'est un test différentiel, pas une preuve.
- **Niveau C/E** : « atteinte » signifie *présente dans le F# généré de la suite, ou référencée par son nom dans ses sources F\**. C'est une mesure
  d'atteignabilité, **plus faible qu'un test dédié par fonction**. Elle ne compte pas les fonctions `inline_for_extraction` ni les instances de classes
  de types que Custard a fondues, et inclut des fonctions seulement appelées par d'autres. Une part importante du reste n'est pas exécutable
  (décroisseurs de relation bien fondée, monade de tactiques, PCM, constantes de réflexion `*_qn`, preuves constructives) : voir la colonne « Non atteintes ».
- Aucune de ces mesures ne vaut preuve d'absence de défaut. Elles ne portent que sur le **backend F#**.

## 3. Ce que ces tests ont trouvé

Détails, correctifs proposés et cas de reproduction : [`UPSTREAM-FSTAR.md`](UPSTREAM-FSTAR.md) §7–14. Rien n'a été déposé en amont.

| Constat | Cas | Résultat |
|---|---|---|
| `List.Tot.Base.splitAt` : totale en F*, lève une exception en F# | `Mx30` | RUN |
| `bool_of_compare`, `compare_of_bool` : signes inversés | `Mx31`, `Mx32` | RUN |
| `list_refb` : le F# généré ne compile pas | `Mx29` | BUILD |
| `print_uintN_hex_pad` : préfixe `0x` en plus | `Mx34` | RUN |
| `String.lowercase/uppercase` Unicode vs ASCII ; `split ""` ; valeur de `compare` ; longueur hors BMP | `Mx36` `Mx37` `Mx38` `Mx33` | RUN |
| `FStar.UInt.sub_mod`/`decr_mod` négatifs (reste euclidien de `Prims.%`) | `Mx41` | RUN |
| `Class.Printable.to_string` sur liste / `Some` : boucle infinie | `Mx40` | RUN (délai) |
| `Printf.sprintf` avec entier machine : `failwith "Prims.admit"` | `Mx46` | RUN |
| `FStar.RBMap.for_any` faux (défaut d'ulib) | `Mx42` | RUN |
| Non réalisés : `either`, `Float.bit_eq/to_string`, `to_string_hex(_pad)`, `Int128.to_string/rotate_*` | `Mx39` `Mx43` `Mx44`, `upstream_tests.sh`, `TMachine` | EXTRACT |
| Paramètre de type fantôme (bibliothèques) | `docs/repro/PhantomTypeParam.fst` | BUILD |

Ce que les tests ont **confirmé** : 202 055 cas d'entiers machine (10 largeurs, 58 casts) concordent avec l'oracle ; `Seq`/`Set`/`Map`/`OrdSet`/`RBSet`/`FiniteMap`/
`Option`/`Order`/`UInt`/`BitVector`/`Printf` (entiers, chaînes, booléens, caractères) concordent ; les 33 programmes amont qui s'extraient s'exécutent correctement.

## 4. Ce qui n'est pas couvert, et pourquoi

- Modules non extractibles (84 sur 221) : types de réflexion/tactiques (`FStarC.Reflection.Types.*`, `Sealed`, `Issue`, `Range`, `Pprint`),
  `Prims.op_Tilde_Minus` (10 modules), `v` d'un entier machine (16) : tableau des causes dans `COUVERTURE-ULIB.md`.
- Fonctions sans définition réductible : leurs attendus viennent du contrat, pas de la sémantique de F* (cas `nonorm` de `ulib_cases.py`).
- `FStar.IO` : `input_*`, fichiers (`open_read_file`…), `print_any` : non réalisés, non testés ; `FStar.Date` : aucune réalisation.
- Les tests tournent sous .NET 10 / Linux ; ni Windows, ni macOS.
