module Mx01_Char
open MxUtil
let main () : FStar.All.ML unit =
  let a = blur 'A' in let z = blur 'z' in
  check (FStar.Char.lowercase a = 'a');
  check (FStar.Char.uppercase z = 'Z');
  check (FStar.Char.int_of_char a = 65);
  FStar.IO.print_string "OK\n"
