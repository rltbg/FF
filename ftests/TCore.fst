module TCore
(* Tests de Core.fst (FNV-1a, analyse décimale, validation) : vecteurs connus, différentiel contre des références
   indépendantes écrites en int, balayage exhaustif de tout l'espace d'entrées utile. *)
open FStar.All
open TUtil
module U8  = FStar.UInt8
module U32 = FStar.UInt32
module C   = FStar.Char
module S   = FStar.String
module B   = FStar.Bytes
open FStar.List.Tot

let bytes_ascii (s:string) : list U8.t = map_u8 (codes_of_string s)

(* u32 attendu, construit à partir d'un int *)
let eq32 (h:U32.t) (n:int) : bool = U32.eq h (u32_of n)

let safe_fnv_utf8 (s:string) : ML (option U32.t) =
  if S.length s <= 4000000 then (Core.lemma_len_maxlen s; Some (Core.fnv_utf8 s)) else None

let rec map_mod128 (l:list int) : Tot (list int) (decreases l) =
  match l with [] -> [] | x :: t -> (x % 128) :: map_mod128 t

let fnv_enc (s:string) : ML (option U32.t) =
  if S.length s <= 4000000 then (Core.lemma_len_maxlen s; Some (Core.fnv_bytes (B.utf8_encode s))) else None

let test_fnv () : ML unit =
  (* vecteurs de draft-eastlake-fnv-21 et calculés indépendamment *)
  check "fnv ''" (eq32 (Core.fnv (blur [])) 0x811c9dc5);
  check "fnv 'a'" (eq32 (Core.fnv (bytes_ascii (blur "a"))) 0xe40c292c);
  check "fnv 'foobar'" (eq32 (Core.fnv (bytes_ascii (blur "foobar"))) 0xbf9cf968);
  check "fnv '\\0'" (eq32 (Core.fnv (blur [0uy])) 0x050c5d1f);
  check "fnv 'a\\0'" (eq32 (Core.fnv (blur [0x61uy; 0uy])) 0x2b24d044);
  check "fnv 'foobar\\0'" (eq32 (Core.fnv (bytes_ascii (blur "foobar") @ [0uy])) 0x0c1c9eb8);
  check "fnv_bytes 'foobar'" (match fnv_enc (blur "foobar") with Some h -> eq32 h 0xbf9cf968 | None -> false);
  check "fnv_bytes vide" (eq32 (Core.fnv_bytes (blur B.empty_bytes)) 0x811c9dc5);
  check "fnv_utf8 'foobar'" (match safe_fnv_utf8 (blur "foobar") with Some h -> eq32 h 0xbf9cf968 | None -> false);
  check "constantes" (eq32 (blur Core.fnv_offset) 2166136261 && eq32 (blur Core.fnv_prime) 16777619);
  check "magic u8" (U8.eq (blur Core.magic) 0xA5uy);
  check "fnv magic" (eq32 (blur Core.fnv_magic) ((xor_bits 2166136261 165 32 * 16777619) % 4294967296));
  (* UTF-8 : é = C3 A9 ; 'Ā' (U+0100) <> '\0' ; unité BMP de 3 octets *)
  check "utf8 é" (match safe_fnv_utf8 (blur "é") with Some h -> eq32 h (ref_fnv [0xC3; 0xA9]) | None -> false);
  check "utf8 Ā <> \\0" (match safe_fnv_utf8 (blur "Ā"), safe_fnv_utf8 (blur "\000") with
                         | Some a, Some b -> not (U32.eq a b) | _ -> false);
  check "utf8 em-tiret" (match safe_fnv_utf8 (blur "—") with Some h -> eq32 h (ref_fnv [0xE2; 0x80; 0x94]) | None -> false)

(* différentiel : fnv (liste), fnv_from/append, fnv_bytes, fnv_utf8 contre la référence en int *)
let test_fnv_random () : ML unit =
  let rec loop (k:nat) : ML unit =
    if k = 0 then () else begin
      let n = rand_below 64 in
      let bs = rand_list n (fun () -> rand_below 256) in
      let bs = blur bs in
      let ub = map_u8 bs in
      let expect = ref_fnv bs in
      check "fnv = ref" (eq32 (Core.fnv ub) expect);
      let cut = rand_below (n + 1) in
      let (a, b) = splitAt cut ub in
      check "fnv_append" (U32.eq (Core.fnv_from Core.fnv_offset (a @ b))
                                 (Core.fnv_from (Core.fnv_from Core.fnv_offset a) b));
      let ascii = map_mod128 bs in
      check "fnv_bytes = ref" (match fnv_enc (blur (string_of_codes ascii)) with Some h -> eq32 h (ref_fnv ascii) | None -> false);
      (* chaîne de codes BMP variés (ASCII, Latin, CJK ; sans substituts) *)
      let codes = rand_list (rand_below 12) (fun () ->
                    match rand_below 4 with
                    | 0 -> rand_below 128 | 1 -> 128 + rand_below 1900 | 2 -> 2048 + rand_below 40000
                    | _ -> 0xE000 + rand_below 8000) in
      let codes = blur codes in
      let s = string_of_codes codes in
      check "fnv_utf8 = ref" (match safe_fnv_utf8 s with Some h -> eq32 h (ref_fnv (ref_utf8 codes)) | None -> false);
      loop (k - 1)
    end in
  loop 20000

(* ---- analyse décimale ---- *)
(* référence : valeur d'une chaîne de chiffres ASCII, None si vide, non numérique ou > 1000 *)
let rec ref_digits (acc:int) (l:list int) : Tot (option int) (decreases l) =
  match l with
  | [] -> Some acc
  | c :: t -> if c >= 48 && c <= 57 then (let a = 10 * acc + (c - 48) in if a > 1000 then None else ref_digits a t) else None

let ref_nat (l:list int) : option int = match l with [] -> None | _ -> ref_digits 0 l

let same_opt (r:option U32.t) (e:option int) : bool =
  match r, e with
  | None, None -> true
  | Some a, Some v -> eq32 a v
  | _ -> false

let nat_s (s:string) : option U32.t = match Core.parse_nat (S.list_of_string s) with Some n -> Some n | None -> None
let age_s (s:string) : option U32.t = match Core.parse_age (S.list_of_string s) with Some n -> Some n | None -> None

let test_parse () : ML unit =
  check "nat ''" (same_opt (nat_s (blur "")) None);
  check "nat '0'" (same_opt (nat_s (blur "0")) (Some 0));
  check "nat '007'" (same_opt (nat_s (blur "007")) (Some 7));
  check "nat '1000'" (same_opt (nat_s (blur "1000")) (Some 1000));
  check "nat '1001'" (same_opt (nat_s (blur "1001")) None);
  check "nat 20 chiffres" (same_opt (nat_s (blur "99999999999999999999")) None);
  check "nat zéros longs" (same_opt (nat_s (blur (S.make 500 '0' ^ "5"))) (Some 5));
  check "nat ' 5'" (same_opt (nat_s (blur " 5")) None);
  check "nat '+5'" (same_opt (nat_s (blur "+5")) None);
  check "nat '-5'" (same_opt (nat_s (blur "-5")) None);
  check "nat '5 '" (same_opt (nat_s (blur "5 ")) None);
  check "nat arabe-indien" (same_opt (nat_s (blur "٣")) None);
  check "nat pleine chasse" (same_opt (nat_s (blur "５")) None);
  check "nat '/' (0x2F)" (same_opt (nat_s (blur "/")) None);
  check "nat ':' (0x3A)" (same_opt (nat_s (blur ":")) None);
  check "age '150'" (same_opt (age_s (blur "150")) (Some 150));
  check "age '151'" (same_opt (age_s (blur "151")) None);
  check "age '0'" (same_opt (age_s (blur "0")) (Some 0));
  check "age 'abc'" (same_opt (age_s (blur "abc")) None);
  check "age_ok 150/151" (Core.age_ok (blur 150ul) && not (Core.age_ok (blur 151ul)));
  (* différentiel contre la référence (lemma_parse_nat : correction fonctionnelle) *)
  let alphabet : list int = [48; 49; 50; 51; 52; 53; 54; 55; 56; 57; 32; 43; 45; 120; 0x663; 0xFF15] in
  let rec loop (k:nat) : ML unit =
    if k = 0 then () else begin
      let codes = blur (rand_list (rand_below 6) (fun () -> pick alphabet)) in
      let s = string_of_codes codes in
      let en = ref_nat codes in
      check "nat diff" (same_opt (nat_s s) en);
      let ea = (match en with Some v -> if v <= 150 then Some v else None | None -> None) in
      check "age diff" (same_opt (age_s s) ea);
      loop (k - 1)
    end in
  loop 200000

(* ---- validation de nom et caractère imprimable ---- *)
let ok_name (s:string) : bool = Core.name_ok (S.list_of_string s)

let test_name () : ML unit =
  check "nom vide" (not (ok_name (blur "")));
  check "nom 1" (ok_name (blur "a"));
  check "nom 20" (ok_name (blur (S.make 20 'a')));
  check "nom 21" (not (ok_name (blur (S.make 21 'a'))));
  check "nom tab" (not (ok_name (blur "a\tb")));
  check "nom 0x1F" (not (ok_name (blur (string_of_codes [97; 31; 98]))));
  check "nom espace" (ok_name (blur " "));
  check "nom ~" (ok_name (blur "~"));
  check "nom DEL" (not (ok_name (blur (string_of_codes [97; 127; 98]))));
  check "nom C1 0x80" (not (ok_name (blur (string_of_codes [97; 128; 98]))));
  check "nom C1 0x9F" (not (ok_name (blur (string_of_codes [97; 159; 98]))));
  check "nom NBSP 0xA0" (ok_name (blur (string_of_codes [97; 160; 98])));
  check "nom accents" (ok_name (blur "Éloïse"));
  (* tous les codes valides en F* : printable <=> pas de contrôle C0/DEL/C1 *)
  let rec all (n:nat) : ML unit =
    if n = 0 then () else begin
      let c = n - 1 in
      if valid_code c then
        check "printable" (Core.printable (blur (chr c)) = (c >= 32 && not (c >= 127 && c <= 159)));
      all c
    end in
  all 65536;
  (* supplémentaires : printable ne dépend que de la plage C0/C1 *)
  check "printable U+1F642" (Core.printable (blur (chr 0x1F642)))

let main () : ML unit =
  test_fnv (); test_fnv_random (); test_parse (); test_name ()
