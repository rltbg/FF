module Mx31_BoolOfCompare
(* FStar.List.Tot.Base.bool_of_compare f x y = (f x y < 0) en F* (ulib/FStar.List.Tot.Base.fst : « true si, et seulement si,
   compare x y est négatif »). Le F# de support (FStarCustard.fs) calcule `f x y > 0I` : le signe est inversé. *)
open MxUtil
module L = FStar.List.Tot
let cmp (a b:int) : int = if a < b then 0 - 1 else if a > b then 1 else 0
let sem () : Lemma (L.bool_of_compare cmp 1 2 = true /\ L.bool_of_compare cmp 2 1 = false) =
  assert_norm (L.bool_of_compare cmp 1 2 = true); assert_norm (L.bool_of_compare cmp 2 1 = false)
let main () : FStar.All.ML unit =
  let a = blur 1 in
  let b = blur 2 in
  check (L.bool_of_compare cmp a b = true);
  check (L.bool_of_compare cmp b a = false);
  FStar.IO.print_string "OK\n"
