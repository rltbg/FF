module Mx08_Option
open MxUtil
let f (x:option int) : int = match x with Some v -> v | None -> -1
let main () : FStar.All.ML unit =
  check (f (blur (Some 4)) = 4);
  check (f (blur None) = -1);
  check (FStar.Option.isSome (blur (Some 1)));
  check (FStar.Option.mapTot (fun x -> x + 1) (blur (Some 1)) = Some 2);
  FStar.IO.print_string "OK\n"
