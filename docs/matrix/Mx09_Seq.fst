module Mx09_Seq
module Seq = FStar.Seq
open MxUtil
let main () : FStar.All.ML unit =
  let x = blur 1 in
  let s = Seq.cons x (Seq.cons 2 Seq.empty) in
  check (Seq.length s = 2);
  FStar.IO.print_string "OK\n"
