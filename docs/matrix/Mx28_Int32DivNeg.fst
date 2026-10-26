module Mx28_Int32DivNeg
(* Division et reste des entiers machine signés, opérandes négatifs : ce que PROUVE F* (assert_norm sur v)
   doit être ce que calcule le F# extrait (int32 de .NET : troncature vers zéro). *)
module I = FStar.Int32
open MxUtil
let sem () : Lemma (I.v (I.div (I.int_to_t (-7)) 2l) = -3 /\ I.v (I.rem (I.int_to_t (-7)) 3l) = -1) =
  assert_norm (I.v (I.div (I.int_to_t (-7)) 2l) = -3);
  assert_norm (I.v (I.rem (I.int_to_t (-7)) 3l) = -1)
let main () : FStar.All.ML unit =
  let m7 = blur (I.int_to_t (-7)) in
  check (I.div m7 2l = I.int_to_t (-3));
  check (I.rem m7 3l = I.int_to_t (-1));
  FStar.IO.print_string "OK\n"
