module Mx17_UInt128
module U = FStar.UInt128
open MxUtil
let main () : FStar.All.ML unit =
  let a = U.uint64_to_uint128 (blur 0xFFFFFFFFFFFFFFFFUL) in
  let b = U.add a a in
  check (U.uint128_to_uint64 b = 0xFFFFFFFFFFFFFFFEUL);
  FStar.IO.print_string "OK\n"
