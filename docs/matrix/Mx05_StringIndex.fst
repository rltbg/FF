module Mx05_StringIndex
module S = FStar.String
open MxUtil
let main () : FStar.All.ML unit =
  let s = blur "hello" in
  check (S.get s 0 = 'h');
  check (S.substring s 1 3 = "ell");
  check (S.compare (blur "a") "b" < 0);
  FStar.IO.print_string "OK\n"
