module Mx24_Float64
module F = FStar.Float64
module I = FStar.Int64
open MxUtil
let main () : FStar.All.ML unit =
  let a = F.of_int (blur 3L) in
  let b = F.mul (F.add a (F.of_int 1L)) (F.of_int 2L) in   (* (3+1)*2 = 8 *)
  check (F.ieee_eq b (F.of_int 8L));
  FStar.IO.print_string "OK\n"
