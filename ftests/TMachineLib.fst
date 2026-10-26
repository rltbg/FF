module TMachineLib
(* Harnais des tests différentiels des entiers machine (FStar.UInt8..64/128, FStar.Int8..64/128).
   L'oracle est écrit ici, en [int] (arithmétique mathématique sur opérandes >= 0 : voir TUtil), indépendamment de
   toute opération machine. Les opérations testées sont passées en fermetures qui construisent les entiers machine
   par uint_to_t/int_to_t gardés, appliquent l'opération et comparent au résultat attendu construit de la même façon
   (aucune conversion machine -> int : [v] n'est pas réalisé en F#). *)
open FStar.All
open TUtil
open FStar.List.Tot

(* une opération : [None] = précondition de la spécification non satisfaite pour ces opérandes (cas ignoré) *)
type bin = int -> int -> int -> option bool    (* a, b, attendu *)
type una = int -> int -> option bool           (* a, attendu *)
type cmp = int -> int -> bool -> option bool   (* a, b, attendu *)

noeq type ops = {
  name: string; bits: nat; signed: bool;
  add_mod: option bin; sub_mod: option bin; mul_mod: option bin;
  add: option bin; sub: option bin; mul: option bin;
  add_us: option bin; sub_us: option bin; mul_us: option bin;     (* *_underspec : spécifiés sans débordement *)
  div: option bin; rem: option bin;
  logand: option bin; logor: option bin; logxor: option bin; lognot: option una;
  shl: option bin; shr: option bin; sar: option bin; rotl: option bin; rotr: option bin;
  eq: cmp; ne: cmp; gt: cmp; gte: cmp; lt: cmp; lte: cmp;
  eq_mask: option bin; gte_mask: option bin;
  to_string: option (int -> string -> bool);
  zero_one: unit -> bool;
}

let rec pw (n:int) : Tot (r:int{r > 0}) (decreases (if n < 0 then 0 else n)) = if n <= 0 then 1 else 2 * pw (n - 1)

(* ---- oracle, int uniquement ---- *)
let rec bitwise (f:int -> int -> int) (a b:int) (k:nat) : Tot int (decreases k) =
  if k = 0 then 0 else f (a % 2) (b % 2) + 2 * bitwise f (a / 2) (b / 2) (k - 1)
let f_and (x y:int) : int = if x = 1 && y = 1 then 1 else 0
let f_or  (x y:int) : int = if x = 1 || y = 1 then 1 else 0
let f_xor (x y:int) : int = if x <> y then 1 else 0

let abs_i (a:int) : int = if a < 0 then 0 - a else a
let to_u (bits:nat) (a:int) : int = if a < 0 then a + pw bits else a
let of_u (bits:nat) (signed:bool) (u:int) : int = if signed && u >= pw (bits - 1) then u - pw bits else u

let lo_of (bits:nat) (signed:bool) : int = if signed then 0 - pw (bits - 1) else 0
let hi_of (bits:nat) (signed:bool) : int = if signed then pw (bits - 1) - 1 else pw bits - 1

(* n bits aléatoires (jusqu'à 128) : 32 bits à la fois *)
let rec rand_bits (chunks:nat) : ML int =
  if chunks = 0 then 0 else rand_next () + 4294967296 * rand_bits (chunks - 1)

(* entier aléatoire de [lo, hi] *)
let rand_range (lo hi:int) : ML int =
  let span = hi - lo + 1 in
  if span <= 0 then lo else lo + rand_bits 5 % span

let edges (bits:nat) (signed:bool) : list int =
  let lo = lo_of bits signed in let hi = hi_of bits signed in
  let cand = [lo; lo + 1; 0 - 2; 0 - 1; 0; 1; 2; 3; 7; 100; hi / 2; hi - 1; hi] in
  filter (fun (x:int) -> x >= lo && x <= hi) cand

let operands (bits:nat) (signed:bool) : ML (list int) =
  let lo = lo_of bits signed in let hi = hi_of bits signed in
  let rec rs (k:nat) : ML (list int) = if k = 0 then [] else (let x = rand_range lo hi in x :: rs (k - 1)) in
  edges bits signed @ rs 20

(* oracle d'une opération binaire/unaire ; None = hors précondition de la spécification *)
let trunc_div (a b:int) : int =
  if b = 0 then 0 else (let q = abs_i a / abs_i b in if (a < 0) <> (b < 0) then 0 - q else q)

let o_add_mod (o:ops) (a b:int) : int = of_u o.bits o.signed ((to_u o.bits a + to_u o.bits b) % pw o.bits)
let o_sub_mod (o:ops) (a b:int) : int = of_u o.bits o.signed ((to_u o.bits a + pw o.bits - to_u o.bits b) % pw o.bits)
let o_mul_mod (o:ops) (a b:int) : int = of_u o.bits o.signed ((to_u o.bits a * to_u o.bits b) % pw o.bits)
let in_range (o:ops) (x:int) : bool = x >= lo_of o.bits o.signed && x <= hi_of o.bits o.signed

let bit_op (o:ops) (f:int -> int -> int) (a b:int) : int =
  of_u o.bits o.signed (bitwise f (to_u o.bits a) (to_u o.bits b) o.bits)

let o_shl (o:ops) (a s:int) : int = of_u o.bits o.signed ((to_u o.bits a * pw s) % pw o.bits)
let o_shr_log (o:ops) (a s:int) : int = of_u o.bits o.signed (to_u o.bits a / pw s)
(* décalage arithmétique : plancher de a / 2^s *)
let o_sar (o:ops) (a s:int) : int = if a >= 0 then a / pw s else 0 - ((0 - a + pw s - 1) / pw s)
let o_rotl (o:ops) (a s:int) : int =
  let u = to_u o.bits a in of_u o.bits o.signed (((u * pw s) % pw o.bits) + u / pw (o.bits - s))
let o_rotr (o:ops) (a s:int) : int =
  let u = to_u o.bits a in of_u o.bits o.signed ((u / pw s) + ((u % pw s) * pw (o.bits - s)))

let rec dec_digits (n:int) (fuel:nat) : Tot string (decreases fuel) =
  if fuel = 0 then "" else if n < 10 then string_of_int n else dec_digits (n / 10) (fuel - 1) ^ string_of_int (n % 10)
let dec_string (a:int) : string = if a < 0 then "-" ^ dec_digits (0 - a) 60 else dec_digits a 60

(* ---- exécution ---- *)
let executed : ref int = alloc 0
let skipped  : ref int = alloc 0

let tally (name:string) (r:option bool) : ML unit =
  match r with
  | Some ok -> executed := !executed + 1; check name ok
  | None -> skipped := !skipped + 1

(* une opération dont aucun cas n'a pu s'exécuter (toutes les préconditions fausses) ne teste rien : échec *)
let nonvacuous (name:string) (before:int) : ML unit =
  check (name ^ " : au moins un cas exécuté") (!executed > before)

let run_bin (name:string) (f:option bin) (oracle:int -> int -> option int) (xs:list int) : ML unit =
  match f with
  | None -> ()
  | Some g ->
    let before = !executed in
    List.iter (fun (a:int) -> List.iter (fun (b:int) ->
      match oracle a b with
      | Some e -> tally name (g a b e)
      | None -> skipped := !skipped + 1) xs) xs;
    nonvacuous name before

let run_shift (o:ops) (name:string) (f:option bin) (oracle:int -> int -> option int) (xs:list int) : ML unit =
  match f with
  | None -> ()
  | Some g ->
    let before = !executed in
    List.iter (fun (a:int) ->
      let rec sh (s:nat) : ML unit =
        if s >= o.bits then () else begin
          (match oracle a s with Some e -> tally name (g a s e) | None -> skipped := !skipped + 1);
          sh (s + 1)
        end in
      sh 0) xs;
    nonvacuous name before

let run_ops (o:ops) : ML unit =
  let xs = operands o.bits o.signed in
  let n s = o.name ^ "." ^ s in
  let some_if (c:bool) (v:int) : option int = if c then Some v else None in
  run_bin (n "add_mod") o.add_mod (fun a b -> Some (o_add_mod o a b)) xs;
  run_bin (n "sub_mod") o.sub_mod (fun a b -> Some (o_sub_mod o a b)) xs;
  run_bin (n "mul_mod") o.mul_mod (fun a b -> Some (o_mul_mod o a b)) xs;
  run_bin (n "add") o.add (fun a b -> some_if (in_range o (a + b)) (a + b)) xs;
  run_bin (n "sub") o.sub (fun a b -> some_if (in_range o (a - b)) (a - b)) xs;
  run_bin (n "mul") o.mul (fun a b -> some_if (in_range o (a * b)) (a * b)) xs;
  run_bin (n "add_underspec") o.add_us (fun a b -> some_if (in_range o (a + b)) (a + b)) xs;
  run_bin (n "sub_underspec") o.sub_us (fun a b -> some_if (in_range o (a - b)) (a - b)) xs;
  run_bin (n "mul_underspec") o.mul_us (fun a b -> some_if (in_range o (a * b)) (a * b)) xs;
  run_bin (n "div") o.div (fun a b -> if b = 0 then None else (let q = trunc_div a b in some_if (in_range o q) q)) xs;
  run_bin (n "rem") o.rem (fun a b -> if b = 0 then None else (let q = trunc_div a b in some_if (in_range o q) (a - q * b))) xs;
  run_bin (n "logand") o.logand (fun a b -> Some (bit_op o f_and a b)) xs;
  run_bin (n "logor") o.logor (fun a b -> Some (bit_op o f_or a b)) xs;
  run_bin (n "logxor") o.logxor (fun a b -> Some (bit_op o f_xor a b)) xs;
  (match o.lognot with
   | Some g -> List.iter (fun (a:int) -> tally (n "lognot") (g a (of_u o.bits o.signed (hi_of o.bits false - to_u o.bits a)))) xs
   | None -> ());
  run_shift o (n "shift_left") o.shl
    (fun a s -> if o.signed then (if a >= 0 && a * pw s <= hi_of o.bits true then Some (a * pw s) else None)
                else Some (o_shl o a s)) xs;
  run_shift o (n "shift_right") o.shr
    (fun a s -> if o.signed then (if a >= 0 then Some (a / pw s) else None) else Some (o_shr_log o a s)) xs;
  run_shift o (n "shift_arithmetic_right") o.sar (fun a s -> Some (o_sar o a s)) xs;
  run_shift o (n "rotate_left") o.rotl (fun a s -> Some (o_rotl o a s)) xs;
  run_shift o (n "rotate_right") o.rotr (fun a s -> Some (o_rotr o a s)) xs;
  let mask = hi_of o.bits false in
  run_bin (n "eq_mask") o.eq_mask (fun a b -> Some (if a = b then mask else 0)) xs;
  run_bin (n "gte_mask") o.gte_mask (fun a b -> Some (if a >= b then mask else 0)) xs;
  List.iter (fun (a:int) -> List.iter (fun (b:int) ->
    tally (n "eq") (o.eq a b (a = b));   tally (n "ne") (o.ne a b (a <> b));
    tally (n "gt") (o.gt a b (a > b));   tally (n "gte") (o.gte a b (a >= b));
    tally (n "lt") (o.lt a b (a < b));   tally (n "lte") (o.lte a b (a <= b))) xs) xs;
  (match o.to_string with
   | Some g -> List.iter (fun (a:int) -> check (n "to_string") (g a (dec_string a))) xs
   | None -> ());
  check (n "zero/one") (o.zero_one ())

let some_b (b:bool) : option bool = Some b
