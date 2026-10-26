module Mx26_UnaryMinus
(* Négation unaire d'un entier non constant : F* la nomme Prims.op_Tilde_Minus ( ~- ). *)
open MxUtil
let main () : FStar.All.ML unit =
  let a = blur 7 in
  check (- a = 0 - 7);
  FStar.IO.print_string "OK\n"
