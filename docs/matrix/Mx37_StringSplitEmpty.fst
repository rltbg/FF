module Mx37_StringSplitEmpty
(* FStar.String.split sur la chaîne VIDE : F* prouve `split ['/'] "" = []` (réalisation OCaml), le F# de support utilise
   String.Split de .NET, qui renvoie [""] (une liste d'un élément). Le reste de la fonction concorde : split ['/'] "a/" = ["a"; ""],
   split ['/'] "/" = [""; ""], split ['a'] "aaa" = ["";"";"";""]. *)
open MxUtil
module S = FStar.String
let sem () : Lemma (S.split ['/'] "" = []) = assert_norm (S.split ['/'] "" = [])
let main () : FStar.All.ML unit =
  check (S.split ['/'] (blur "") = []);
  FStar.IO.print_string "OK\n"
