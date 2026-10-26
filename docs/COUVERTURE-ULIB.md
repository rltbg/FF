# Couverture d'ulib par la suite de tests F*

Balayage de 221 modules d'ulib (`scripts/ulib_sweep.sh`, extraction en bibliothèque + compilation F#) : BUILD 7, EXTRACT 84, OK 61, VIDE 69.

- **OK** : le module s'extrait et le F# compile ; **VIDE** : rien d'exécutable (spécifications, lemmes, types) ; **EXTRACT** : erreur de Custard (histogramme dans `docs/ULIB-COUVERTURE.md`) ; **BUILD** : le F# généré ne compile pas.

Parmi les modules OK, définitions exécutables atteintes par la suite : **264 sur 537** (49 %). « Atteinte » = présente dans le F# généré du programme de test (voir l'en-tête de `scripts/coverage_ulib.py`).

## Causes d'échec d'extraction (modules EXTRACT)

| Cause | Modules | Exemples |
|---|---|---|
| greffon de tactique (Error 238) | 21 | FStar.Reflection.TermEq, FStar.Reflection.TermEq.Simple, FStar.Reflection.V2.Compare, FStar.Reflection.V2.Formula … |
| `v` d'un entier machine (fonction de spécification appelée dans du code exécutable) | 16 | FStar.Endianness, FStar.Int.Cast, FStar.Int128, FStar.Int16 … |
| type sans réalisation F# : FStarC.Reflection.Types.term | 15 | FStar.Class.Embeddable, FStar.Reflection.TermSpec, FStar.Reflection.V2.Arith, FStar.Reflection.V2.Collect … |
| fonction sans définition ni réalisation F# : Prims.op_Tilde_Minus | 10 | FStar.BV, FStar.Int, FStar.Math.Euclid, FStar.Math.Lib … |
| type sans réalisation F# : FStar.Sealed.sealed | 3 | FStar.Sealed.Inhabited, FStar.Stubs.Reflection.V2.Data, FStar.Stubs.Tactics.Unseal |
| Error 364 (argument d'un binder monomorphisé) | 2 | FStar.Class.Ord.Raw, FStar.Dyn |
| type sans réalisation F# : FStar.Issue.issue | 2 | FStar.Stubs.Tactics.Types, FStar.Stubs.Tactics.V2.Builtins |
| Error 379 | 1 | FStar.Algebra.Monoid |
| type sans réalisation F# : FStar.Bytes.lbytes | 1 | FStar.Bytes |
| type sans réalisation F# : FStar.Char.char_code | 1 | FStar.Char |
| type sans réalisation F# : FStar.Pervasives.either | 1 | FStar.DependentMap |
| type sans réalisation F# : FStar.Pprint.document | 1 | FStar.Errors.Msg |
| type sans réalisation F# : FStar.Issue.issue_level_string | 1 | FStar.Issue |
| fonction sans définition ni réalisation F# : FStar.List.iteri_aux | 1 | FStar.List |
| Warning 382 (paramètre effacé d'un externe) | 1 | FStar.List.Tot.Base |
| type sans réalisation F# : FStar.Pervasives.pattern | 1 | FStar.Pervasives |
| type sans réalisation F# : FStar.Range.range | 1 | FStar.Range |
| type sans réalisation F# : FStarC.Reflection.Types.binder | 1 | FStar.Reflection.V2.Derived |
| fonction sans définition ni réalisation F# : FStar.String.maxlen | 1 | FStar.String |
| type sans réalisation F# : FStarC.Reflection.Types.name | 1 | FStar.Stubs.Reflection.Types |
| type sans réalisation F# : FStarC.Reflection.Types.namedv | 1 | FStar.Stubs.Syntax.Syntax |
| échec interne (Universe variable not found) | 1 | FStar.Tactics.PatternMatching |

Modules BUILD (le F# généré ne compile pas) : FStar.Fin, FStar.Functions, FStar.Injection, FStar.IntegerIntervals, FStar.Seq.Permutation, FStar.Sequence.Permutation, FStar.Tactics.CanonCommSwaps — `FS0035` (paramètre de type fantôme, `docs/UPSTREAM-FSTAR.md` §14).

## Détail par module OK

| Module | Définitions | Atteintes | Non atteintes |
|---|---|---|---|
| `FStar.Algebra.CommMonoid` | 2 | 0 | int_plus_cm, int_multiply_cm |
| `FStar.Algebra.CommMonoid.Equiv` | 3 | 0 | equality_equiv, int_plus_cm, int_multiply_cm |
| `FStar.Algebra.CommMonoid.Fold` | 2 | 0 | init_func_from_expr, fold |
| `FStar.Algebra.CommMonoid.Fold.Nested` | 2 | 0 | transpose_generator, double_fold |
| `FStar.BigOps` | 1 | 0 | normal |
| `FStar.Bijection` | 2 | 0 | o, mk_cbij |
| `FStar.BitVector` | 12 | 12 |  |
| `FStar.Class.Add` | 3 | 0 | add_int, add_bool, add_list |
| `FStar.Class.Eq` | 9 | 0 | Raw_eq_instance_of_eqtype, eq_instance_of_eqtype__int, int_has_eq, eq_instance_of_eqtype__unit, unit_has_eq, eq_instance_of_eqtype__bool, bool_has_eq, eq_instance_of_eqtype__string, string_has_eq |
| `FStar.Class.Eq.Raw` | 6 | 1 | eq_instance_of_eqtype, int_has_eq, unit_has_eq, bool_has_eq, string_has_eq |
| `FStar.Class.Printable` | 15 | 0 | printable_unit, printable_bool, printable_nat, printable_int, printable_string, printable_char, printable_byte, printable_int8, printable_uint8, printable_int16, printable_uint16, printable_int32 … |
| `FStar.Class.TotalOrder.Raw` | 3 | 1 | uu___0, uu___1 |
| `FStar.Constructive` | 6 | 0 | eq_ind, ceq_symm, ceq_trans, cfalse_elim, false_elim2, false_elim |
| `FStar.Custard` | 1 | 0 | dyn |
| `FStar.Error` | 5 | 0 | perror, correct, unexpected, unreachable, if_ideal |
| `FStar.FiniteMap.Base` | 13 | 10 | key_in_item_list, item_list_doesnt_repeat_keys, glue |
| `FStar.FiniteSet.Base` | 10 | 9 | list_nonrepeating |
| `FStar.Float32` | 2 | 2 |  |
| `FStar.Float64` | 2 | 2 |  |
| `FStar.FunctionalExtensionality` | 3 | 0 | on_domain, on_dom, on |
| `FStar.FunctionalQueue` | 8 | 8 |  |
| `FStar.IFC` | 5 | 0 | hide, return, map, join, op_let_Greater_Greater |
| `FStar.Integers` | 14 | 0 | norm, nat_of_width, nat_of_fixed_width, width_of_sw, f_int, f_nat, f_nat_int_pos, f_uint_8, f_int_16, g, h, i … |
| `FStar.LexicographicOrdering` | 1 | 0 | tuple_to_dep_tuple |
| `FStar.List.Pure.Base` | 4 | 4 |  |
| `FStar.List.Tot.Properties` | 3 | 0 | rev', rev'T, sorted |
| `FStar.Map` | 10 | 9 | domain |
| `FStar.Math.Fermat` | 1 | 0 | pow |
| `FStar.Matrix` | 24 | 0 | get_ij, get_i, get_j, transpose_ji, seq_of_matrix, ijth, matrix_of_seq, foldm, init, transposed_matrix_gen, matrix_equiv, matrix_add_generator … |
| `FStar.Option` | 7 | 5 | map, get |
| `FStar.OrdMap` | 10 | 10 |  |
| `FStar.OrdMapProps` | 1 | 0 | fold |
| `FStar.OrdSet` | 45 | 34 | sorted, tail, head, mem_of, last_lib, last, liat_lib, liat, inv, where, as_set |
| `FStar.OrdSetProps` | 3 | 0 | fold, insert, union' |
| `FStar.Order` | 12 | 12 |  |
| `FStar.PCM` | 5 | 0 | op, frame_preserving_val_to_fp_upd, no_op_is_frame_preserving, compose_frame_preserving_updates, frame_preserving_subframe |
| `FStar.PartialMap` | 7 | 7 |  |
| `FStar.Pervasives.Native` | 2 | 0 | fst, snd |
| `FStar.Printf` | 7 | 4 | string_of_arg, string_of_dirs, ext_sprintf |
| `FStar.RBMap` | 7 | 7 |  |
| `FStar.RBSet` | 6 | 6 |  |
| `FStar.Reflection.Const` | 50 | 0 | imp_qn, and_qn, or_qn, not_qn, iff_qn, eq2_qn, eq1_qn, true_qn, false_qn, b2t_qn, forall_qn, exists_qn … |
| `FStar.Seq.Base` | 23 | 18 | seq_to_list, seq_of_list, init, createEmpty, op_At_Bar |
| `FStar.Seq.Equiv` | 1 | 0 | seq_equiv |
| `FStar.Seq.Properties` | 27 | 24 | sort_lseq, foldr_snoc, map_seq |
| `FStar.Sequence.Base` | 13 | 10 | op_Dollar_Colon_Colon, op_Dollar_Plus, rank |
| `FStar.Sequence.Seq` | 2 | 0 | sequence_of_seq, seq_of_sequence |
| `FStar.Sequence.Util` | 9 | 6 | un_build, split, fold_back |
| `FStar.Set` | 10 | 10 |  |
| `FStar.Tactics.BreakVC` | 1 | 0 | break_vc |
| `FStar.Tactics.Effect` | 7 | 0 | tac_return, tac_bind, lift_div_tac, lift_ndet_tac, rewrite_with_tactic, synth_by_tactic, assume_safe |
| `FStar.Tactics.Util` | 21 | 0 | map, concatMap, __mapi, mapi, iter, iteri_aux, iteri, fold_left, fold_right, zip, filter, filter_map_acc … |
| `FStar.UInt` | 54 | 51 | decr_mod, sub_mod, xor |
| `FStar.Universe` | 4 | 0 | raise_val, downgrade_val, lift_dom, lift_codom |
| `FStar.Universe.PCM` | 2 | 0 | raise, raise_frame_preserving_upd |
| `FStar.WellFounded` | 2 | 0 | fix_F, fix |
| `FStar.WellFoundedRelation` | 16 | 0 | default_decreaser, default_wfr, empty_decreaser, empty_wfr, acc_decreaser, acc_to_wfr, subrelation_decreaser, subrelation_to_wfr, inverse_image_decreaser, inverse_image_to_wfr, lex_nondep_decreaser, lex_nondep_wfr … |
| `Prims` | 11 | 2 | op_Hat, unsafe_coerce, op_Star, op_Minus, op_Less_Equals, min, op_Greater_Equals, op_Tilde_Minus, abs |
