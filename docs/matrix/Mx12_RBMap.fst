module Mx12_RBMap
(* FStar.RBMap : arbre rouge-noir en F* pur, avec classe de type ord *)
module R = FStar.RBMap
open MxUtil
let main () : FStar.All.ML unit =
  let k = blur 2 in
  let m = R.add k "deux" (R.add 1 "un" (R.empty ())) in
  check (R.lookup 2 m = Some "deux");
  check (R.mem 1 m);
  FStar.IO.print_string "OK\n"
