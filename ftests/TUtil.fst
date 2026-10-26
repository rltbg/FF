module TUtil
(* Outillage des tests, entièrement en F*. Trois règles issues de CLAUDE.md :
   - Custard évalue les termes clos à l'extraction : toute entrée d'un test passe par [blur] (un effet) ;
   - [FStar.UInt32.v] etc. n'ont pas de réalisation F# : aucune conversion « entier machine -> int » à l'exécution.
     Les références travaillent donc sur des [int] et construisent les entiers machine par [uint_to_t] gardé ;
   - / et % de Prims.int sont euclidiens en F* et tronqués dans le F# extrait : les opérandes sont toujours >= 0. *)
open FStar.All
module U8  = FStar.UInt8
module U32 = FStar.UInt32
module C   = FStar.Char
module S   = FStar.String
open FStar.List.Tot

let checks : ref int = alloc 0
let fails  : ref int = alloc 0

(* noms distincts des vérifications en échec (les 60 premiers) : un nom n'est imprimé qu'une fois *)
let failed_names : ref (list string) = alloc []

let check (name:string) (ok:bool) : ML unit =
  checks := !checks + 1;
  if not ok then begin
    fails := !fails + 1;
    if not (mem name !failed_names) && length !failed_names < 60 then begin
      failed_names := name :: !failed_names;
      FStar.IO.print_string ("FAIL: " ^ name ^ "\n")
    end
  end

let blur (#a:Type) (x:a) : ML a = let r = alloc x in !r

(* Générateur congruentiel linéaire (Knuth MMIX), arithmétique mathématique sur int, opérandes >= 0. *)
let seed : ref int = alloc 12345
let rand_next () : ML int =
  let s = (!seed * 6364136223846793005 + 1442695040888963407) % 18446744073709551616 in
  seed := s;
  s / 4294967296
let rand_below (n:pos) : ML (r:int{r >= 0 /\ r < n}) =
  let r = rand_next () % n in if r >= 0 && r < n then r else 0

(* entiers machine construits à partir d'un int, gardés (hors plage : 0) *)
let u8_of  (n:int) : U8.t  = if n >= 0 && n < 256 then U8.uint_to_t n else 0uy
let u32_of (n:int) : U32.t = if n >= 0 && n < 4294967296 then U32.uint_to_t n else 0ul

(* caractère de code n s'il est valide en F* (hors substituts, et 0xD7FF exclu par la spécification de char_code) *)
let valid_code (n:int) : bool = (n >= 0 && n < 0xD7FF) || (n >= 0xE000 && n <= 0x10FFFF)
let chr (n:int) : C.char = if valid_code n then C.char_of_int n else 'a'

(* ---- références indépendantes, en int ---- *)
let rec xor_bits (a b:int) (k:nat) : Tot int (decreases k) =
  if k = 0 then 0
  else (if a % 2 <> b % 2 then 1 else 0) + 2 * xor_bits (a / 2) (b / 2) (k - 1)

(* FNV-1a 32 bits sur une liste d'octets (int), sans aucun entier machine *)
let rec ref_fnv_from (h:int) (l:list int) : Tot int (decreases l) =
  match l with
  | [] -> h
  | b :: t -> ref_fnv_from ((xor_bits h b 32 * 16777619) % 4294967296) t
let ref_fnv (l:list int) : int = ref_fnv_from 2166136261 l

(* UTF-8 d'une unité de code BMP (hors substituts) : encodage écrit à la main *)
let utf8_of_unit (n:int) : list int =
  if n < 128 then [n]
  else if n < 2048 then [192 + n / 64; 128 + n % 64]
  else [224 + n / 4096; 128 + (n / 64) % 64; 128 + n % 64]

let rec ref_utf8 (l:list int) : Tot (list int) (decreases l) =
  match l with [] -> [] | n :: t -> utf8_of_unit n @ ref_utf8 t

let rec map_chr (l:list int) : Tot (list C.char) (decreases l) =
  match l with [] -> [] | n :: t -> chr n :: map_chr t

let string_of_codes (l:list int) : string = S.string_of_list (map_chr l)

let rec rand_list (n:nat) (f:unit -> ML int) : ML (list int) =
  if n = 0 then [] else (let x = f () in x :: rand_list (n - 1) f)

let rec map_u8 (l:list int) : Tot (list U8.t) (decreases l) =
  match l with [] -> [] | n :: t -> u8_of n :: map_u8 t

(* choix d'un élément d'une liste non vide *)
let pick (#a:Type) (l:list a{Cons? l}) : ML a =
  let i = rand_below (length l) in index l i

(* codes (int) des unités d'une chaîne *)
let rec codes_of_chars (l:list C.char) : Tot (list int) (decreases l) =
  match l with [] -> [] | c :: t -> C.int_of_char c :: codes_of_chars t
let codes_of_string (s:string) : list int = codes_of_chars (S.list_of_string s)

let report () : ML unit =
  FStar.IO.print_string ("checks=" ^ string_of_int !checks ^ " fails=" ^ string_of_int !fails ^ "\n")
