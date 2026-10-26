module Mx16_Cast
module C = FStar.Int.Cast
open MxUtil
let main () : FStar.All.ML unit =
  check (C.uint8_to_uint32 (blur 200uy) = 200ul);
  check (C.uint32_to_uint64 (blur 4000000000ul) = 4000000000UL);
  check (C.uint32_to_uint8 (blur 0x1FFul) = 255uy);
  FStar.IO.print_string "OK\n"
