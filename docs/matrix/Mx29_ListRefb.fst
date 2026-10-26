module Mx29_ListRefb
(* FStar.List.Tot.Base.list_refb : le prédicat #p (bool) n'est pas effacé, Custard le passe en argument, mais le F#
   de support définit `list_refb (l : 'a list)` à un seul argument -> erreur de compilation F# (FS0003). *)
open MxUtil
module L = FStar.List.Tot
let pos_i (x:int) : bool = x > 0
let main () : FStar.All.ML unit =
  let pl = blur [1; 2; 3] in
  if L.for_all pos_i pl then check (L.length (L.list_refb #int #pos_i pl) = 3);
  FStar.IO.print_string "OK\n"
