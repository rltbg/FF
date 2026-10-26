module Mx38_StringCompareValue
(* FStar.String.compare : la documentation promet le SIGNE (négatif si s1 < s2) ; le normaliseur de F* donne -1, 0 ou 1
   (assert_norm (compare "a" "c" = -1) est prouvé). Le F# de support renvoie String.CompareOrdinal, c'est-à-dire la DIFFÉRENCE des
   unités de code (-2 ici). Une preuve qui s'appuie sur la valeur exacte -1 est fausse à l'exécution ; le signe, lui, concorde. *)
open MxUtil
module S = FStar.String
let sem () : Lemma (S.compare "a" "c" = -1) = assert_norm (S.compare "a" "c" = -1)
let main () : FStar.All.ML unit =
  check (S.compare (blur "a") "c" = -1);
  FStar.IO.print_string "OK\n"
