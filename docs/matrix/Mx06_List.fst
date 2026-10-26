module Mx06_List
open FStar.List.Tot
open MxUtil
let main () : FStar.All.ML unit =
  let l = blur [3; 1; 2] in
  check (map (fun x -> x + 1) l = [4; 2; 3]);
  check (filter (fun x -> x > 1) l = [3; 2]);
  check (fold_left (fun a x -> a + x) 0 l = 6);
  check (rev l = [2; 1; 3]);
  check (l @ [9] = [3; 1; 2; 9]);
  check (length l = 3);
  check (nth l 1 = Some 1);
  check (mem 2 l);
  check (assoc 2 (blur [(1, "a"); (2, "b")]) = Some "b");
  check (for_all (fun x -> x > 0) l);
  check (existsb (fun x -> x = 2) l);
  check (find (fun x -> x < 3) l = Some 1);
  check (partition (fun x -> x > 1) l = ([3; 2], [1]));
  check (fst (split (blur [(1, 'a'); (2, 'b')])) = [1; 2]);
  FStar.IO.print_string "OK\n"
