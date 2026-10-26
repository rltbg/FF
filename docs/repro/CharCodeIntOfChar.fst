module CharCodeIntOfChar
(* Contournement A (utilisé par Core.fst) : FStar.Char.int_of_char, réalisé, renvoie un nat (bigint en F#). *)
let is_digit (c:FStar.Char.char) : bool = let n = FStar.Char.int_of_char c in 48 <= n && n <= 57
let main () : FStar.All.ML unit =
  FStar.IO.print_string (if is_digit '7' then "7 est un chiffre\n" else "KO\n");
  FStar.IO.print_string (if is_digit 'x' then "KO\n" else "x n'est pas un chiffre\n")
