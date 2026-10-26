module Mx14_UInt64
module U = FStar.UInt64
module U32 = FStar.UInt32
open MxUtil
let main () : FStar.All.ML unit =
  let m = blur 0xFFFFFFFFFFFFFFFFUL in let one = blur 1UL in let sh = blur 63ul in
  check (U.add_mod m one = 0UL);
  if U32.lt sh 64ul then check (U.shift_left one sh = 0x8000000000000000UL);
  check (U.logxor (blur 0xF0UL) 0xFFUL = 0x0FUL);
  check (U.mul_mod (blur 0x100000000UL) 0x100000000UL = 0UL);
  FStar.IO.print_string "OK\n"
