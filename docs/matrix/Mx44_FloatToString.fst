module Mx44_FloatToString
(* FStar.Float64.to_string : déclaré dans FStar.Float64.fsti, réalisé en OCaml seulement ; ni définition F* ni réalisation F#
   (Error 395). *)
open MxUtil
module F64 = FStar.Float64
let main () : FStar.All.ML unit =
  let z = blur (F64.of_literal "1.5") in
  check (F64.to_string z <> "");
  FStar.IO.print_string "OK\n"
