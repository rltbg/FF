module Mx36_StringCase
(* FStar.String.lowercase / uppercase : le normaliseur de F* (réalisation OCaml, ASCII seulement) laisse les lettres non ASCII
   inchangées : lowercase "ÉA" = "Éa" est PROUVÉ par F*. Le F# de support utilise ToLowerInvariant / ToUpperInvariant (Unicode) :
   à l'exécution on obtient "éa". Un fait prouvé en F* est donc faux à l'exécution pour du texte non ASCII. *)
open MxUtil
module S = FStar.String
let sem () : Lemma (S.lowercase "ÉA" = "Éa" /\ S.uppercase "éa" = "éA") =
  assert_norm (S.lowercase "ÉA" = "Éa"); assert_norm (S.uppercase "éa" = "éA")
let main () : FStar.All.ML unit =
  check (S.lowercase (blur "ÉA") = "Éa");
  check (S.uppercase (blur "éa") = "éA");
  FStar.IO.print_string "OK\n"
