module Mx46_PrintfMachineInt
(* FStar.Printf.sprintf avec un argument entier machine (%y %i %l %L %uy %us %ul %uL) : le résultat attendu est évident (la
   réalisation OCaml imprime 1), mais le F# extrait appelle `failwith "Prims.admit"` : string_of_arg est déroulé sur FStar.Int8.to_string dont la définition F*
   est `admit ()` ; la réalisation .NET (Prims.string_of_sint8) n'est pas choisie dans ce chemin, alors qu'elle l'est pour
   FStar.Class.Printable.to_string 7y. Les formats %d %s %b %c et %% fonctionnent (Mx45). *)
open MxUtil
let main () : FStar.All.ML unit =
  let a : FStar.Int8.t = blur 1y in
  check (FStar.Printf.sprintf "%y" a = "1");
  FStar.IO.print_string "OK\n"
