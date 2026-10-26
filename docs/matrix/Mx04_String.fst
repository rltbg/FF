module Mx04_String
module S = FStar.String
open MxUtil
let main () : FStar.All.ML unit =
  let n = blur 3 in let s = blur "héllo" in let p = blur "a/b/c" in
  check (S.make n 'a' = "aaa");
  check (S.length s = 5);
  check (S.concat ", " (blur ["a"; "b"; "c"]) = "a, b, c");
  check (blur "ab" ^ "cd" = "abcd");
  check (S.split ['/'] p = ["a"; "b"; "c"]);
  check (S.uppercase (blur "abc") = "ABC");
  check (S.lowercase (blur "ABC") = "abc");
  check (S.index_of (blur "hello") 'l' = 2);
  check (S.list_of_string (blur "abc") = ['a'; 'b'; 'c']);
  check (S.string_of_list (blur ['x'; 'y']) = "xy");
  check (S.string_of_char (blur 'q') = "q");
  FStar.IO.print_string "OK\n"
