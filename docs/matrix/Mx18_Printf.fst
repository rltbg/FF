module Mx18_Printf
open MxUtil
let main () : FStar.All.ML unit =
  check (FStar.Printf.sprintf "%d-%s" (blur 42) (blur "ok") = "42-ok");
  FStar.IO.print_string "OK\n"
