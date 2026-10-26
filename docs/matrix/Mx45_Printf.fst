module Mx45_Printf
(* FStar.Printf.sprintf : formats typés par dépendance (le type du résultat dépend de la chaîne de format). *)
open MxUtil
let main () : FStar.All.ML unit =
  let s = FStar.Printf.sprintf "%d-%s" (blur 3) (blur "x") in
  check (s = "3-x");
  FStar.IO.print_string "OK\n"
