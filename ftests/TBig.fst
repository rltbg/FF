module TBig
(* Tests de Big.fst : exhaustifs sur les 100 000 lignes et les 38 000 lignes de texte, contre des chaînes construites
   ici à partir de codes de caractères (aucune fonction de Big n'est réutilisée pour construire l'attendu). *)
open FStar.All
open TUtil
module U32 = FStar.UInt32
module S   = FStar.String
open FStar.List.Tot

(* six chiffres décimaux de n (n >= 0) *)
let d6 (n:int) : list int =
  [48 + (n / 100000) % 10; 48 + (n / 10000) % 10; 48 + (n / 1000) % 10; 48 + (n / 100) % 10; 48 + (n / 10) % 10; 48 + n % 10]

let rec dec (n:int) (fuel:nat) : Tot (list int) (decreases fuel) =
  if fuel = 0 then [] else if n < 10 then [48 + n] else dec (n / 10) (fuel - 1) @ [48 + n % 10]

let exp_row (i:int) : string =
  string_of_codes ([76; 105; 103; 110; 101; 32] @ d6 i @ [32; 0x2014; 32] @ [100;111;110;110;233;101] @ [32; 99; 244; 116; 233; 32; 104; 244; 116; 101])

let exp_line (i:int) : string =
  string_of_codes ([84; 101; 120; 116; 101; 32] @ d6 i @ [32; 0x2014; 32; 233; 224; 252; 32] @ dec (i % 97) 3)

let src0 () : ML U32.t = blur 0ul
let src1 () : ML U32.t = blur 1ul

let test_rows () : ML unit =
  let s0 = src0 () in
  let rec loop (i:nat) : ML unit =
    if i >= 100000 then () else begin
      let r = Big.item s0 i in
      check "row = attendu" (r = exp_row i);
      check "row_index réciproque" (Big.row_index r = i);
      check "index_of src0" (Big.index_of s0 r = i);
      loop (i + 1)
    end in
  loop 0;
  check "taille d'une ligne" (S.length (Big.item s0 12) = 31);
  (* chaînes étrangères : jamais d'indice *)
  let foreign = ["" ; "Ligne "; "Ligne 00000"; "Ligne 000001 — autre"; "Ligne 00000x — donnée côté hôte";
                 "ligne 000001 — donnée côté hôte"; "Texte 000001 — éàü 1"; "Ligne 000001 — donnée côté hôte "; "Ligne -00001 — donnée côté hôte"] in
  List.iter (fun (s:string) -> check "étranger -> -1" (Big.row_index (blur s) = -1)) foreign;
  (* hors plage : formatée comme une ligne mais d'indice >= 100000 *)
  check "hors plage 100000" (Big.row_index (blur (exp_row 100000)) = -1);
  check "hors plage 999999" (Big.row_index (blur (exp_row 999999)) = -1);
  check "dernière 99999" (Big.row_index (blur (exp_row 99999)) = 99999)

let test_lines () : ML unit =
  let s1 = src1 () in
  let rec loop (i:nat) : ML unit =
    if i >= 38000 then () else begin
      let r = Big.item s1 i in
      check "line = attendu" (r = exp_line i);
      check "line_index réciproque" (Big.line_index r = i);
      check "index_of src1" (Big.index_of s1 r = i);
      loop (i + 1)
    end in
  loop 0;
  check "ligne 38000 hors plage" (Big.line_index (blur (exp_line 38000)) = -1);
  check "ligne étrangère" (Big.line_index (blur (exp_row 5)) = -1 && Big.line_index (blur "") = -1)

let test_sources () : ML unit =
  (* source inconnue : rien *)
  let s2 = blur 2ul in
  check "src inconnue : item" (Big.item s2 0 = "" && Big.item s2 99999 = "");
  check "src inconnue : index_of" (Big.index_of s2 (exp_row 3) = -1 && Big.index_of s2 (exp_line 3) = -1);
  check "src inconnue : texte" (Big.text_of s2 = "" && Big.text_of (blur 0ul) = "" && Big.text_of (blur 0xFFFFFFFFul) = "");
  (* index_of croisé : une ligne de la source 1 n'est pas dans la source 0 et inversement *)
  check "index_of croisé" (Big.index_of (src0 ()) (exp_line 3) = -1 && Big.index_of (src1 ()) (exp_row 3) = -1);
  check "constantes" (U32.eq (blur Big.src_rows) 0ul && U32.eq (blur Big.src_text) 1ul && blur Big.rows_count = 100000 && blur Big.text_lines = 38000)

(* le texte complet : 38 000 lignes terminées par '\n', 832 080 unités UTF-16 (1 022 080 octets UTF-8) *)
let rec count_nl (l:list FStar.Char.char) (acc:int) : Tot int (decreases l) =
  match l with [] -> acc | c :: t -> count_nl t (if FStar.Char.int_of_char c = 10 then acc + 1 else acc)

(* S.sub a des préconditions (0 <= i, 0 <= l, i + l <= length) : on les teste à l'exécution *)
let sub_is (t:string) (i l:int) (e:string) : bool =
  if i >= 0 && l >= 0 && i + l <= S.length t then S.sub t i l = e else false

let test_text () : ML unit =
  let t = Big.text_of (src1 ()) in
  check "texte : longueur UTF-16" (S.length t = 832080);
  check "texte : 38000 retours" (count_nl (S.list_of_string t) 0 = 38000);
  check "texte : début" (sub_is t 0 (S.length (exp_line 0) + 1) (exp_line 0 ^ "\n"));
  check "texte : fin" (sub_is t (832080 - S.length (exp_line 37999) - 1) (S.length (exp_line 37999) + 1) (exp_line 37999 ^ "\n"));
  (* empreinte indépendante : calculée par un script externe puis figée ici (voir docs) *)
  check "texte : FNV-1a UTF-8" (if S.length t <= 4000000 then (Core.lemma_len_maxlen t; U32.eq (Core.fnv_utf8 t) (u32_of 1791175457)) else false)

let main () : ML unit =
  test_rows (); test_lines (); test_sources (); test_text ()
