module Mx20_Bytes
module B = FStar.Bytes
module U32 = FStar.UInt32
open MxUtil
let main () : FStar.All.ML unit =
  let b = B.utf8_encode (blur "é") in
  check (B.len b = 2ul);
  if U32.lt 0ul (B.len b) then check (B.get b 0ul = 0xC3uy);
  if U32.lt (B.len b) 1000ul then check (B.hex_of_bytes (B.append b b) = "c3a9c3a9");
  FStar.IO.print_string "OK\n"
