module Mx10_Set
module Set = FStar.Set
open MxUtil
let main () : FStar.All.ML unit =
  let x = blur 1 in
  let s = Set.add x Set.empty in
  check (FStar.Set.mem 1 s);
  FStar.IO.print_string "OK\n"
