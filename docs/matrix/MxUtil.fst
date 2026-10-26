module MxUtil
(* Utilitaires de la matrice. [blur] lit la valeur depuis une référence mutable : c'est un effet,
   donc Custard ne peut pas évaluer le terme à l'extraction (il le fait pour les termes clos,
   ce qui effacerait le code qu'on veut tester : voir docs/MATRICE-FSTAR.md). *)
open FStar.All
let blur (#a:Type) (x:a) : ML a = let r = alloc x in !r
let check (b:bool) : ML unit =
  if not b then (FStar.IO.print_string "FAIL\n"; FStar.All.exit 1)
