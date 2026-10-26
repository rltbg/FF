module Mx43_FloatBitEq
(* FStar.Float64.bit_eq (et Float32.bit_eq) : Custard le laisse volontairement en appel à la bibliothèque de support
   (Builtins.fst : « bit_eq is deliberately absent … it stays a call into the support library »), mais FStarCustard.fs ne le
   définit pas : Error 395 « FStar.Float64.bit_eq has no F* definition and no F# realization ». to_string est dans le même cas. *)
open MxUtil
module F64 = FStar.Float64
let main () : FStar.All.ML unit =
  let z = blur (F64.of_literal "0.0") in
  check (F64.bit_eq z (F64.of_literal "0.0"));
  FStar.IO.print_string "OK\n"
