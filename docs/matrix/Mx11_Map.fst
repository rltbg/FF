module Mx11_Map
module M = FStar.Map
open MxUtil
let main () : FStar.All.ML unit =
  let v = blur 5 in
  let m = M.upd (M.const 0) 1 v in
  check (M.sel m 1 = 5);
  FStar.IO.print_string "OK\n"
