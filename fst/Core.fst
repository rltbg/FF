module Core
(* Logique pure vérifiée : hachage FNV-1a 32 bits, analyse décimale bornée, validation. *)
module U8  = FStar.UInt8
module U32 = FStar.UInt32
module C   = FStar.Char
open FStar.List.Tot

(* --- FNV-1a 32 bits --- *)
let fnv_offset : U32.t = 2166136261ul
let fnv_prime  : U32.t = 16777619ul

let fnv_step (h:U32.t) (b:U8.t) : U32.t =
  U32.mul_mod (U32.logxor h (FStar.Int.Cast.uint8_to_uint32 b)) fnv_prime

let rec fnv_from (h:U32.t) (l:list U8.t) : Tot U32.t (decreases l) =
  match l with
  | [] -> h
  | b :: t -> fnv_from (fnv_step h b) t

let fnv (l:list U8.t) : U32.t = fnv_from fnv_offset l

let rec fnv_append (h:U32.t) (a b:list U8.t)
  : Lemma (ensures fnv_from h (a @ b) == fnv_from (fnv_from h a) b) (decreases a)
  = match a with [] -> () | x :: t -> fnv_append (fnv_step h x) t b

(* octet de test littéral (volontairement écrit 0xA5uy) *)
let magic : U8.t = 0xA5uy
let fnv_magic : U32.t = fnv_step fnv_offset magic

(* --- analyse décimale bornée par 1000 --- *)
let is_digit (c:C.char) : bool =
  let n = C.int_of_char c in 48 <= n && n <= 57

let digit_val (c:C.char{is_digit c}) : (d:U32.t{U32.v d <= 9}) =
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

(* --- validation --- *)
let age_ok (n:U32.t) : bool = U32.lte n 150ul

let parse_age (l:list C.char) : option (n:U32.t{U32.v n <= 150}) =
  match parse_nat l with
  | Some n -> if age_ok n then Some n else None
  | None -> None

let name_ok (l:list C.char) : bool =
  let n = length l in n >= 1 && n <= 20 && for_all (fun c -> 32 <= C.int_of_char c) l

(* spec pure, volontairement SANS noextract *)
let well_formed_age (l:list C.char) : prop = Some? (parse_age l)

let lemma_parse_bounded (l:list C.char)
  : Lemma (match parse_age l with Some n -> U32.v n <= 150 | None -> True) = ()

let lemma_empty_rejected () : Lemma (parse_nat [] == None) = ()
let lemma_name_len (l:list C.char) : Lemma (requires name_ok l) (ensures length l >= 1 /\ length l <= 20) = ()
