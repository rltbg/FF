module Mx22_Poly
open MxUtil
type tree (a:Type) = | Leaf | Node of tree a & a & tree a
let rec size (#a:Type) (t:tree a) : nat = match t with Leaf -> 0 | Node (l, _, r) -> size l + 1 + size r
let rec even (n:nat) : bool = if n = 0 then true else odd (n - 1)
and odd (n:nat) : bool = if n = 0 then false else even (n - 1)
let main () : FStar.All.ML unit =
  let x = blur 1 in
  check (size (Node (Node (Leaf, x, Leaf), 2, Leaf)) = 2);
  let n : nat = blur 10 in
  check (even n);
  if n >= 3 then check (odd (n - 3));
  FStar.IO.print_string "OK\n"
