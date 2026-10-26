module Mx19_PrimsInt
(* Prims.int = bigint. Les assert_norm disent ce que PROUVE F* ; les check disent ce que calcule le F# extrait. *)
open MxUtil
let main () : FStar.All.ML unit =
  let a = blur 7 in
  check (pow2 100 = 1267650600228229401496703205376);
  check (a * 123456789012345678901234567890 = 864197523086419752308641975230);
  check (a / 2 = 3 && a % 3 = 1);          (* opérandes positifs : euclidien = tronqué *)
  FStar.IO.print_string "OK\n"
