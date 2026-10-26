module CharCodeWorkaround
module U32 = FStar.UInt32
module C   = FStar.Char

(* Contournement B : déclaration locale (axiome) de u32_of_char, avec la cible .NET donnée par custard_extern.
   Le type de retour n'est pas FStar.Char.char_code : Custard ne rencontre jamais ce type. *)
[@@custard_extern "FStar_Char.u32_of_char"]
assume val u32_of_char (c:C.char) : Tot (n:U32.t{n == C.u32_of_char c})

let is_digit (c:C.char) : bool =
  let n = u32_of_char c in U32.lte 48ul n && U32.lte n 57ul

let main () : FStar.All.ML unit =
  FStar.IO.print_string (if is_digit '7' then "7 est un chiffre\n" else "KO\n");
  FStar.IO.print_string (if is_digit 'x' then "KO\n" else "x n'est pas un chiffre\n")
