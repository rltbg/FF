module Mx32_CompareOfBool
(* FStar.List.Tot.Base.compare_of_bool rel x y = -1 si rel x y, 0 si x = y, 1 sinon (ulib/FStar.List.Tot.Base.fst).
   Le F# de support (FStarCustard.fs) renvoie 1 / 0 / -1 : les signes sont inversés. *)
open MxUtil
module L = FStar.List.Tot
let lt (a b:int) : bool = a < b
let sem () : Lemma (L.compare_of_bool lt 1 2 = -1 /\ L.compare_of_bool lt 2 2 = 0 /\ L.compare_of_bool lt 3 2 = 1) =
  assert_norm (L.compare_of_bool lt 1 2 = -1); assert_norm (L.compare_of_bool lt 2 2 = 0); assert_norm (L.compare_of_bool lt 3 2 = 1)
let main () : FStar.All.ML unit =
  let a = blur 1 in
  let b = blur 2 in
  let c = blur 3 in
  check (L.compare_of_bool lt a b = -1);
  check (L.compare_of_bool lt b b = 0);
  check (L.compare_of_bool lt c b = 1);
  FStar.IO.print_string "OK\n"
