module Mx25_PrimsIntDivNeg
(* Opérandes NÉGATIFS : F* prouve (-7)/2 = -4 et (-7)%3 = 2 (Prims.fst : division et reste euclidiens).
   Le F# extrait utilise les opérateurs BigInteger, qui tronquent vers zéro (-3 et -1). *)
open MxUtil
let sem () : Lemma (((-7) / 2 = -4) /\ ((-7) % 3 = 2) /\ (7 / (-3) = -2) /\ (7 % (-3) = 1)) =
  assert_norm ((-7) / 2 = -4); assert_norm ((-7) % 3 = 2); assert_norm (7 / (-3) = -2); assert_norm (7 % (-3) = 1)
let main () : FStar.All.ML unit =
  let m7 = blur 0 - 7 in
  check (m7 / 2 = -4);
  check (m7 % 3 = 2);
  FStar.IO.print_string "OK\n"
