module Mx15_Int64
module I = FStar.Int64
open MxUtil
let main () : FStar.All.ML unit =
  let a = blur 5L in
  if I.lt a 1000L && I.gt a (I.int_to_t (-1000)) then begin
    check (I.sub a 7L = I.int_to_t (-2));
    check (I.add a 30L = 35L)
  end;
  check (I.gt a 3L);
  FStar.IO.print_string "OK\n"
