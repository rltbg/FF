module Mx23_Exn
open MxUtil
let main () : FStar.All.ML unit =
  let r = FStar.All.try_with (fun () -> FStar.All.failwith (blur "boom")) (fun _ -> 7) in
  check (r = 7);
  FStar.IO.print_string "OK\n"
