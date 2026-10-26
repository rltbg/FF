module Mx41_UIntSubMod
(* Conséquence de Prims.op_Percent (docs/UPSTREAM-FSTAR.md §1) dans la bibliothèque standard elle-même : FStar.UInt.sub_mod est
   défini par (a - b) % pow2 n. F* prouve sub_mod #8 5 10 = 251 (reste euclidien) ; le F# extrait calcule (5 - 10) % 256 avec le
   reste TRONQUÉ de BigInteger et renvoie -5, valeur HORS de uint_t 8. Même chose pour decr_mod #8 0 (-1 au lieu de 255) et
   sub_mod #64 0 1. (Les modules FStar.UInt8..64, eux, sont des entiers .NET natifs : non concernés.) *)
open MxUtil
module UI = FStar.UInt
let sem () : Lemma (UI.sub_mod #8 5 10 = 251 /\ UI.decr_mod #8 0 = 255) =
  assert_norm (UI.sub_mod #8 5 10 = 251); assert_norm (UI.decr_mod #8 0 = 255)
let main () : FStar.All.ML unit =
  let a : UI.uint_t 8 = blur 5 in
  let b : UI.uint_t 8 = blur 10 in
  check (UI.sub_mod #8 a b = 251);
  check (UI.decr_mod #8 (blur 0) = 255);
  FStar.IO.print_string "OK\n"
