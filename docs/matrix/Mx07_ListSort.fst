module Mx07_ListSort
open MxUtil
let cmp (a b:int) : int = if a < b then -1 else if a > b then 1 else 0
let main () : FStar.All.ML unit =
  check (FStar.List.Tot.sortWith cmp (blur [3; 1; 2]) = [1; 2; 3]);
  FStar.IO.print_string "OK\n"
