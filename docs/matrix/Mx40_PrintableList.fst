module Mx40_PrintableList
(* FStar.Class.Printable.to_string sur une LISTE : F* avertit (« fuel exhausted during typeclass resolution. This usually indicates a
   loop in your instances ») car l'instance printable_ref (x:a{p x}) s'applique à tout type ; la dictionnaire résolu est cyclique.
   Le normaliseur de F* prouve pourtant to_string [1;2;3] = "[1; 2; 3]". Custard compile la projection cyclique en
   `let rec f tmp = f tmp` (voir FStar_Class_Printable___proj__Mkprintable__item__to_string__int dans le F# généré) : le programme
   BOUCLE à l'infini dès qu'on imprime un élément de liste. Sur un int seul, tout va bien. *)
open MxUtil
module Pr = FStar.Class.Printable
let sem () : Lemma (Pr.to_string [1; 2; 3] = "[1; 2; 3]") = assert_norm (Pr.to_string [1; 2; 3] = "[1; 2; 3]")
let main () : FStar.All.ML unit =
  check (Pr.to_string (blur 5) = "5");
  check (Pr.to_string (blur [1; 2; 3]) = "[1; 2; 3]");
  FStar.IO.print_string "OK\n"
