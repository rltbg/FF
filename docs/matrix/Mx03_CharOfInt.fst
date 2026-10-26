module Mx03_CharOfInt
open MxUtil
let main () : FStar.All.ML unit =
  let n = blur 66 in
  check (FStar.Char.char_of_int n = 'B');
  FStar.IO.print_string "OK\n"
