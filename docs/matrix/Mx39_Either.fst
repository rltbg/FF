module Mx39_Either
(* Le type FStar.Pervasives.either (Inl / Inr) n'a pas de réalisation F# : Error 395 « the type FStar.Pervasives.either is realized by
   hand-written OCaml and has no F# realization ». C'est un type de base de la bibliothèque standard (et de FStar.Class.Printable,
   FStar.Universe, ...). Contournement : définir son propre type somme. *)
open MxUtil
let main () : FStar.All.ML unit =
  let e : either int bool = Inl (blur 3) in
  check (Inl? e);
  FStar.IO.print_string "OK\n"
