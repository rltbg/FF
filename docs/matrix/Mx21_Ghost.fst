module Mx21_Ghost
open MxUtil
let g (#a:Type) (x:FStar.Ghost.erased a) : Tot unit = ()
let main () : FStar.All.ML unit =
  g (FStar.Ghost.hide (blur 3));
  FStar.IO.print_string "OK\n"
