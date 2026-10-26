module TString
(* Prims (entiers, chaînes), FStar.Char et FStar.String : fonctions réalisées par Custard sur int = bigint,
   char = char .NET, string = string .NET (UTF-16). Attendus écrits à la main, propriétés des lemmes de l'interface. *)
open FStar.All
open TUtil
module C = FStar.Char
module S = FStar.String
open FStar.List.Tot

let rec ref_cmp (a b:list int) : Tot int (decreases a) =
  match a, b with
  | [], [] -> 0
  | [], _ -> 0 - 1
  | _, [] -> 1
  | x :: s, y :: t -> if x < y then 0 - 1 else if x > y then 1 else ref_cmp s t

let sign (n:int) : int = if n < 0 then 0 - 1 else if n > 0 then 1 else 0

(* ---------------------------------------------------------------------- Prims *)
let test_prims () : ML unit =
  let a = blur 123456789012345678901234567890 in
  let b = blur 987654321 in
  check "op_Plus" (a + b = 123456789012345678902222222211);
  check "op_Minus" (a - b = 123456789012345678900246913569);
  check "op_Star" (b * b = 975461057789971041);
  check "op_Plus neg" (blur (0 - 5) + 3 = 0 - 2);
  check "op_Minus neg" (blur 3 - 5 = 0 - 2);
  check "op_Star neg" (blur (0 - 4) * 5 = 0 - 20);
  (* / et % : opérandes >= 0 (voir Mx25 pour les négatifs) *)
  let rec dm (k:nat) : ML unit =
    if k = 0 then () else begin
      let x = TMachineLib.rand_bits 3 in let y = 1 + TMachineLib.rand_bits 2 % 1000000007 in
      (if x >= 0 && y > 0 then begin
        let q = x / y in let r = x % y in
        check "op_Slash/op_Percent : x = q*y + r" (x = q * y + r);
        check "op_Percent : 0 <= r < y" (r >= 0 && r < y)
      end else check "opérandes >= 0" false);
      dm (k - 1)
    end in
  dm 2000;
  check "op_Slash 7/2" (blur 7 / 2 = 3);
  check "op_Percent 7%3" (blur 7 % 3 = 1);
  check "op_Slash 100/10" (blur 100 / 10 = 10 && blur 100 % 10 = 0);
  check "compare ops" (let x = blur 3 in let y = blur 5 in
                       x < y && x <= y && y > x && y >= x && x <= x && x >= x && not (x > y) && not (x >= y) && not (y < x) && not (y <= x));
  check "compare ops bigint" (blur 100000000000000000000 > blur 99999999999999999999);
  let rec pw (n:nat) : ML unit =
    if n > 130 then () else begin
      check "pow2" (pow2 n = TMachineLib.pw n);
      pw (n + 1)
    end in
  pw 0;
  check "strcat/op_Hat" (Prims.strcat (blur "ab") "cd" = "abcd" && (blur "x" ^ "yz") = "xyz" && (blur "" ^ "") = "");
  check "string_of_bool" (string_of_bool (blur true) = "true" && string_of_bool (blur false) = "false");
  let rec soi (k:nat) : ML unit =
    if k = 0 then () else begin
      let n = TMachineLib.rand_bits 3 in
      check "string_of_int >= 0" (string_of_int n = TMachineLib.dec_string n);
      check "string_of_int < 0" (string_of_int (0 - n) = TMachineLib.dec_string (0 - n));
      soi (k - 1)
    end in
  soi 500;
  check "string_of_int 0" (string_of_int (blur 0) = "0" && string_of_int (blur (0 - 7)) = "-7" && string_of_int (blur 2147483648) = "2147483648")

(* ---------------------------------------------------------------------- Char *)
let test_char () : ML unit =
  check "int_of_char 'A'" (C.int_of_char (blur 'A') = 65);
  check "int_of_char 'é'" (C.int_of_char (blur 'é') = 233);
  check "int_of_char '€'" (C.int_of_char (blur '€') = 8364);
  check "int_of_char '\\000'" (C.int_of_char (blur (chr 0)) = 0);
  check "char_of_int" (C.char_of_int (blur 97) = 'a' && C.char_of_int (blur 0x20AC) = '€');
  (* aller-retour sur tous les codes valides du BMP (spécification de char_code) *)
  let rec rt (n:nat) : ML unit =
    if n = 0 then () else begin
      let c = n - 1 in
      (if valid_code c && c <= 0xFFFF then check "char_of_int/int_of_char" (C.int_of_char (C.char_of_int (blur c)) = c));
      rt c
    end in
  rt 65536;
  (* lowercase / uppercase : lettres ASCII, Latin-1, Grec, Cyrillique ; idempotence ; non-lettres inchangés *)
  let rec az (c:nat) : ML unit =
    if c > 127 then () else begin
      let lo = if c >= 65 && c <= 90 then c + 32 else c in
      let up = if c >= 97 && c <= 122 then c - 32 else c in
      check "lowercase ASCII" (C.int_of_char (C.lowercase (blur (chr c))) = lo);
      check "uppercase ASCII" (C.int_of_char (C.uppercase (blur (chr c))) = up);
      az (c + 1)
    end in
  az 0;
  (* non ASCII : F* laisse inchangé (String.lowercase "ÉA" = "Éa" prouvé), .NET convertit : docs/matrix/Mx36_StringCase.fst *)
  check "lowercase '1' inchangé" (C.lowercase (blur '1') = '1' && C.uppercase (blur '€') = '€')

(* ---------------------------------------------------------------------- String *)
let ascii_chars : list int = [97; 98; 99; 100; 32; 47; 44; 233; 8364; 0x44F]

let rec_str (n:nat) : ML string = string_of_codes (rand_list n (fun () -> pick ascii_chars))

let sub_is (s:string) (i l:int) (e:string) : bool =
  if i >= 0 && l >= 0 && i + l <= S.length s then S.sub s i l = e else false

let idx (s:string) (i:int) : option C.char = if i >= 0 && i < S.length s then Some (S.index s i) else None

let test_string () : ML unit =
  let s = blur "héllo wörld €" in
  check "length" (S.length s = 13 && S.length (blur "") = 0 && S.strlen s = 13);
  check "list_of_string" (codes_of_string s = [104; 233; 108; 108; 111; 32; 119; 246; 114; 108; 100; 32; 8364]);
  check "string_of_list" (string_of_codes [104; 233; 8364] = "hé€" && string_of_codes [] = "");
  check "make" (S.make 3 'x' = "xxx" && S.length (S.make 0 'x') = 0 && S.make 2 (blur '€') = "€€");
  check "string_of_char" (S.string_of_char (blur 'é') = "é");
  (* FStar.String.strcat / op_Hat : cités par supported_realizations mais non déclarés dans FStar.String.fsti (inaccessibles) *)
  check "op_Hat" ((blur "é" ^ "€") = "é€");
  check "index/get" (idx s 1 = Some 'é' && idx s 12 = Some '€' && idx s 13 = None && idx s (0 - 1) = None);
  check "get (ML)" (S.get s 7 = 'ö');
  check "sub" (sub_is s 0 5 "héllo" && sub_is s 6 5 "wörld" && sub_is s 12 1 "€" && sub_is s 3 0 "");
  check "substring (ML)" (S.substring s 6 5 = "wörld");
  check "sub hors plage refusé" (not (sub_is s 10 4 ""));
  check "index_of" (S.index_of s 'l' = 2 && S.index_of s 'é' = 1 && S.index_of s '€' = 12 && S.index_of s 'z' = (0 - 1)
                    && S.index_of (blur "") 'a' = (0 - 1));
  check "lowercase/uppercase ASCII" (S.lowercase (blur "AbC 1") = "abc 1" && S.uppercase (blur "aBc 1") = "ABC 1");
  check "concat" (S.concat (blur ", ") ["a"; "b"; "c"] = "a, b, c" && S.concat "-" [] = "" && S.concat "-" ["x"] = "x"
                  && S.concat "" ["a"; "b"] = "ab");
  check "split" (S.split ['/'] (blur "a/b/c") = ["a"; "b"; "c"] && S.split ['/'] (blur "a//b") = ["a"; ""; "b"]
                 && S.split ['/'; ','] (blur "a/b,c") = ["a"; "b"; "c"] && S.split ['/'] (blur "abc") = ["abc"]);
  check "collect (ML)" (S.collect (fun (c:C.char) -> S.make 2 c) (blur "ab") = "aabb");
  (* compare : signe de l'ordre lexicographique par unités UTF-16 *)
  check "compare" (sign (S.compare (blur "a") "b") = (0 - 1) && sign (S.compare (blur "b") "a") = 1 && S.compare (blur "x") "x" = 0
                   && sign (S.compare (blur "ab") "abc") = (0 - 1) && sign (S.compare (blur "") "a") = (0 - 1));
  (* propriétés (lemmes de l'interface), sur des chaînes aléatoires *)
  let rec props (k:nat) : ML unit =
    if k = 0 then () else begin
      let a = blur (rec_str (rand_below 12)) in
      let b = blur (rec_str (rand_below 12)) in
      check "string_of_list_of_string" (S.string_of_list (S.list_of_string a) = a);
      check "concat_length" (S.length (a ^ b) = S.length a + S.length b);
      check "list_of_concat" (S.list_of_string (a ^ b) = S.list_of_string a @ S.list_of_string b);
      check "length = strlen" (S.length a = S.strlen a && S.length a = length (S.list_of_string a));
      check "compare = ref" (sign (S.compare a b) = ref_cmp (codes_of_string a) (codes_of_string b));
      check "compare antisym" (sign (S.compare a b) = 0 - sign (S.compare b a));
      check "split/concat '/'" (S.concat "/" (S.split ['/'] a) = a);
      check "lowercase idempotent" (S.lowercase (S.lowercase a) = S.lowercase a);
      check "index = list index" (match S.list_of_string a with
                                  | [] -> true
                                  | _ :: _ -> let i = rand_below (S.length a) in
                                              (if i >= 0 && i < S.length a then S.index a i = index (S.list_of_string a) i else false));
      check "index_of = première position" (match S.list_of_string a with
                                            | [] -> S.index_of a 'a' = 0 - 1
                                            | c :: _ -> S.index_of a c = 0);
      props (k - 1)
    end in
  props 2000

let main () : ML unit = test_prims (); test_char (); test_string ()
