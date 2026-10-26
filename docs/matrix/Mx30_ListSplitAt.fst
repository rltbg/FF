module Mx30_ListSplitAt
(* FStar.List.Tot.Base.splitAt est TOTALE en F* : `splitAt n l = (l, [])` si n > length l (ulib/FStar.List.Tot.Base.fst).
   Le F# de support appelle List.splitAt de FSharp.Core, qui LÈVE InvalidOperationException dans ce cas. *)
open MxUtil
module L = FStar.List.Tot
let main () : FStar.All.ML unit =
  let l = blur [1; 2; 3] in
  let n = blur 20 in
  if n >= 0 then check (L.splitAt n l = ([1; 2; 3], []));
  FStar.IO.print_string "OK\n"
