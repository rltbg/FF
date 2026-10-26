module Mx13_OrdSet
module O = FStar.OrdSet
open MxUtil
let leq (a b:int) : bool = a <= b
let main () : FStar.All.ML unit =
  let k = blur 2 in
  let s = O.union #int #leq (O.singleton #int #leq 1) (O.singleton #int #leq k) in
  check (O.mem #int #leq 2 s);
  FStar.IO.print_string "OK\n"
