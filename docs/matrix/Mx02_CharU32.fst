module Mx02_CharU32
open MxUtil
(* u32_of_char : Error 395 attendue (docs/FSTAR-char_code.md) *)
let main () : FStar.All.ML unit =
  let a = blur 'A' in
  check (FStar.Char.u32_of_char a = 65ul);
  FStar.IO.print_string "OK\n"
