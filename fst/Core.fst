module Core
(* Logique pure vérifiée : FNV-1a 32 bits (draft-eastlake-fnv-21), analyse décimale bornée, validation de nom. *)
module U8  = FStar.UInt8
module U32 = FStar.UInt32
module C   = FStar.Char
module B   = FStar.Bytes
module Str = FStar.String
open FStar.List.Tot

(* ------------------------------------------------------------------ *)
(* FNV-1a 32 bits. Constantes : draft-eastlake-fnv-21, §2 (prime) et §2.3 (offset basis). *)
let fnv_offset : U32.t = 0x811C9DC5ul   (* 2166136261 *)
let fnv_prime  : U32.t = 0x01000193ul   (* 16777619 *)

(* hash = (hash xor octet) * prime mod 2^32 *)
let fnv_step (h:U32.t) (b:U8.t) : U32.t =
  U32.mul_mod (U32.logxor h (FStar.Int.Cast.uint8_to_uint32 b)) fnv_prime

(* Spécification sur une liste d'octets. *)
let rec fnv_from (h:U32.t) (l:list U8.t) : Tot U32.t (decreases l) =
  match l with
  | [] -> h
  | b :: t -> fnv_from (fnv_step h b) t

let fnv (l:list U8.t) : U32.t = fnv_from fnv_offset l

let rec fnv_append (h:U32.t) (a b:list U8.t)
  : Lemma (ensures fnv_from h (a @ b) == fnv_from (fnv_from h a) b) (decreases a)
  = match a with [] -> () | x :: t -> fnv_append (fnv_step h x) t b

(* Implémentation sur FStar.Bytes (byte[] en F#), prouvée égale à la spécification. *)
noextract
let rec bytes_from (b:B.bytes) (i:U32.t{U32.v i <= B.length b})
  : Tot (list U8.t) (decreases (B.length b - U32.v i)) =
  if U32.eq i (B.len b) then [] else B.get b i :: bytes_from b (U32.add i 1ul)

let rec fnv_bytes_from (h:U32.t) (b:B.bytes) (i:U32.t{U32.v i <= B.length b})
  : Tot U32.t (decreases (B.length b - U32.v i)) =
  if U32.eq i (B.len b) then h else fnv_bytes_from (fnv_step h (B.get b i)) b (U32.add i 1ul)

let rec lemma_fnv_bytes (h:U32.t) (b:B.bytes) (i:U32.t{U32.v i <= B.length b})
  : Lemma (ensures fnv_bytes_from h b i == fnv_from h (bytes_from b i)) (decreases (B.length b - U32.v i))
  = if U32.eq i (B.len b) then () else lemma_fnv_bytes (fnv_step h (B.get b i)) b (U32.add i 1ul)

let fnv_bytes (b:B.bytes) : (h:U32.t{h == fnv (bytes_from b 0ul)}) =
  lemma_fnv_bytes fnv_offset b 0ul;
  fnv_bytes_from fnv_offset b 0ul

(* Empreinte d'une chaîne = FNV-1a de son encodage UTF-8. *)
let fnv_utf8 (s:string{Str.maxlen s (pow2 30)}) : U32.t = fnv_bytes (B.utf8_encode s)

(* Témoin d'extraction d'un littéral u8 (écrit 0xA5uy). *)
let magic : U8.t = 0xA5uy
let fnv_magic : U32.t = fnv_step fnv_offset magic

(* ------------------------------------------------------------------ *)
(* Analyse décimale bornée par 1000. *)
let is_digit (c:C.char) : bool =
  let n = C.int_of_char c in 48 <= n && n <= 57

let digit_val (c:C.char{is_digit c}) : (d:U32.t{U32.v d == C.int_of_char c - 48}) =
  U32.uint_to_t (C.int_of_char c - 48)

let rec parse_digits (acc:U32.t{U32.v acc <= 1000}) (l:list C.char)
  : Tot (option (n:U32.t{U32.v n <= 1000})) (decreases l) =
  match l with
  | [] -> Some acc
  | c :: t ->
    if is_digit c then
      let a' = U32.add (U32.mul acc 10ul) (digit_val c) in
      if U32.lte a' 1000ul then parse_digits a' t else None
    else None

let parse_nat (l:list C.char) : option (n:U32.t{U32.v n <= 1000}) =
  match l with [] -> None | _ -> parse_digits 0ul l

(* Spécification : valeur décimale mathématique (non extraite). *)
noextract
let rec all_digits (l:list C.char) : bool =
  match l with [] -> true | c :: t -> is_digit c && all_digits t

noextract
let rec dec_value (acc:nat) (l:list C.char{all_digits l}) : Tot nat (decreases l) =
  match l with
  | [] -> acc
  | c :: t -> dec_value (10 * acc + (C.int_of_char c - 48)) t

let rec lemma_dec_mono (acc:nat) (l:list C.char{all_digits l})
  : Lemma (ensures dec_value acc l >= acc) (decreases l)
  = match l with [] -> () | c :: t -> lemma_dec_mono (10 * acc + (C.int_of_char c - 48)) t

(* Correction fonctionnelle : Some n <=> que des chiffres et valeur <= 1000, et n est cette valeur. *)
let rec lemma_parse_digits (acc:U32.t{U32.v acc <= 1000}) (l:list C.char)
  : Lemma (ensures (match parse_digits acc l with
                    | Some n -> all_digits l /\ U32.v n == dec_value (U32.v acc) l
                    | None -> ~(all_digits l) \/ dec_value (U32.v acc) l > 1000))
          (decreases l)
  = match l with
    | [] -> ()
    | c :: t ->
      if is_digit c then begin
        let a' = 10 * U32.v acc + (C.int_of_char c - 48) in
        if a' <= 1000 then lemma_parse_digits (U32.uint_to_t a') t
        else if all_digits t then lemma_dec_mono a' t else ()
      end

let lemma_parse_nat (l:list C.char)
  : Lemma (match parse_nat l with
           | Some n -> Cons? l /\ all_digits l /\ U32.v n == dec_value 0 l
           | None -> Nil? l \/ ~(all_digits l) \/ dec_value 0 l > 1000)
  = match l with [] -> () | _ -> lemma_parse_digits 0ul l

(* ------------------------------------------------------------------ *)
(* Validation. *)
let age_ok (n:U32.t) : bool = U32.lte n 150ul

let parse_age (l:list C.char) : option (n:U32.t{U32.v n <= 150}) =
  match parse_nat l with
  | Some n -> if age_ok n then Some n else None
  | None -> None

(* Imprimable = ni contrôle C0 (< 0x20), ni DEL (0x7F), ni contrôle C1 (0x80..0x9F).
   En .NET, un char est une unité UTF-16 : la longueur compte des unités UTF-16. *)
let printable (c:C.char) : bool =
  let n = C.int_of_char c in 32 <= n && not (127 <= n && n <= 159)

let name_ok (l:list C.char) : bool =
  let n = length l in 1 <= n && n <= 20 && for_all printable l

(* Spécification pure de type prop : éliminée à l'extraction sans noextract. *)
let well_formed_age (l:list C.char) : prop = Some? (parse_age l)

let lemma_parse_bounded (l:list C.char)
  : Lemma (match parse_age l with Some n -> U32.v n <= 150 | None -> True) = ()

let lemma_empty_rejected () : Lemma (parse_nat [] == None) = ()

let lemma_name_len (l:list C.char)
  : Lemma (requires name_ok l) (ensures length l >= 1 /\ length l <= 20) = ()

let lemma_name_ok_maxlen (s:string)
  : Lemma (requires name_ok (Str.list_of_string s)) (ensures Str.maxlen s (pow2 30)) = ()
