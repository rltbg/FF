module Mx27_PrimsAbs
(* Prims.abs est défini en F* par `if x >= 0 then x else -x` : sa négation interne est Prims.op_Tilde_Minus. *)
open MxUtil
let main () : FStar.All.ML unit =
  check (abs (0 - blur 7) = 7);
  FStar.IO.print_string "OK\n"
