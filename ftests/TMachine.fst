module TMachine
(* GÉNÉRÉ par scripts/gen_tmachine.py : tests différentiels des entiers machine, une instance de TMachineLib par largeur.
   Ne pas éditer à la main. *)
open FStar.All
open TUtil
open TMachineLib
module U32 = FStar.UInt32

let mk32 (n:int) : option (x:U32.t{U32.v x == n}) = if n >= 0 && n < 4294967296 then Some (U32.uint_to_t n) else None

module M_uint8 = FStar.UInt8
let mk_uint8 (n:int) : option (x:M_uint8.t{M_uint8.v x == n}) = if n >= 0 && n <= 255 then Some (M_uint8.uint_to_t n) else None
let ops_uint8 : ops = {
  name = "UInt8";
  bits = 8;
  signed = false;
  add_mod = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.add_mod x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub_mod = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.sub_mod x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul_mod = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.mul_mod x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  add = (Some (fun (a:int) (b:int) (e:int) -> if a + b <= 255 then (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.add x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub = (Some (fun (a:int) (b:int) (e:int) -> if a - b >= 0 then (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.sub x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul = (Some (fun (a:int) (b:int) (e:int) -> if a * b <= 255 then (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.mul x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  add_us = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.add_underspec x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub_us = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.sub_underspec x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul_us = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.mul_underspec x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  div = (Some (fun (a:int) (b:int) (e:int) -> if b <> 0 then (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.div x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rem = (Some (fun (a:int) (b:int) (e:int) -> if b <> 0 then (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.rem x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logand = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.logand x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logor = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.logor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logxor = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.logxor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  lognot = (Some (fun (a:int) (e:int) -> (match mk_uint8 a with Some x -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.lognot x) z) | None -> Some false) | None -> Some false)));
  shl = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 8 then (match mk_uint8 a with Some x -> (match mk32 s with Some c -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.shift_left x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  shr = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 8 then (match mk_uint8 a with Some x -> (match mk32 s with Some c -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.shift_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sar = None;
  rotl = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 8 then (match mk_uint8 a with Some x -> (match mk32 s with Some c -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.rotate_left x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rotr = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 8 then (match mk_uint8 a with Some x -> (match mk32 s with Some c -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.rotate_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  eq = (fun (a:int) (b:int) (e:bool) -> (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> some_b ((M_uint8.eq x y) = e) | None -> Some false) | None -> Some false));
  ne = (fun (a:int) (b:int) (e:bool) -> (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> some_b ((M_uint8.ne x y) = e) | None -> Some false) | None -> Some false));
  gt = (fun (a:int) (b:int) (e:bool) -> (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> some_b ((M_uint8.gt x y) = e) | None -> Some false) | None -> Some false));
  gte = (fun (a:int) (b:int) (e:bool) -> (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> some_b ((M_uint8.gte x y) = e) | None -> Some false) | None -> Some false));
  lt = (fun (a:int) (b:int) (e:bool) -> (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> some_b ((M_uint8.lt x y) = e) | None -> Some false) | None -> Some false));
  lte = (fun (a:int) (b:int) (e:bool) -> (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> some_b ((M_uint8.lte x y) = e) | None -> Some false) | None -> Some false));
  eq_mask = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.eq_mask x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  gte_mask = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint8 a with Some x -> (match mk_uint8 b with Some y -> (match mk_uint8 e with Some z -> some_b (M_uint8.eq (M_uint8.gte_mask x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  to_string = (Some (fun (a:int) (s:string) -> (match mk_uint8 a with Some x -> M_uint8.to_string x = s | None -> false)));
  zero_one = (fun () -> M_uint8.eq M_uint8.zero (M_uint8.uint_to_t 0) && M_uint8.eq M_uint8.one (M_uint8.uint_to_t 1)) }

module M_uint16 = FStar.UInt16
let mk_uint16 (n:int) : option (x:M_uint16.t{M_uint16.v x == n}) = if n >= 0 && n <= 65535 then Some (M_uint16.uint_to_t n) else None
let ops_uint16 : ops = {
  name = "UInt16";
  bits = 16;
  signed = false;
  add_mod = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.add_mod x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub_mod = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.sub_mod x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul_mod = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.mul_mod x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  add = (Some (fun (a:int) (b:int) (e:int) -> if a + b <= 65535 then (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.add x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub = (Some (fun (a:int) (b:int) (e:int) -> if a - b >= 0 then (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.sub x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul = (Some (fun (a:int) (b:int) (e:int) -> if a * b <= 65535 then (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.mul x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  add_us = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.add_underspec x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub_us = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.sub_underspec x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul_us = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.mul_underspec x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  div = (Some (fun (a:int) (b:int) (e:int) -> if b <> 0 then (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.div x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rem = (Some (fun (a:int) (b:int) (e:int) -> if b <> 0 then (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.rem x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logand = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.logand x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logor = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.logor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logxor = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.logxor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  lognot = (Some (fun (a:int) (e:int) -> (match mk_uint16 a with Some x -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.lognot x) z) | None -> Some false) | None -> Some false)));
  shl = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 16 then (match mk_uint16 a with Some x -> (match mk32 s with Some c -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.shift_left x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  shr = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 16 then (match mk_uint16 a with Some x -> (match mk32 s with Some c -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.shift_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sar = None;
  rotl = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 16 then (match mk_uint16 a with Some x -> (match mk32 s with Some c -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.rotate_left x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rotr = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 16 then (match mk_uint16 a with Some x -> (match mk32 s with Some c -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.rotate_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  eq = (fun (a:int) (b:int) (e:bool) -> (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> some_b ((M_uint16.eq x y) = e) | None -> Some false) | None -> Some false));
  ne = (fun (a:int) (b:int) (e:bool) -> (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> some_b ((M_uint16.ne x y) = e) | None -> Some false) | None -> Some false));
  gt = (fun (a:int) (b:int) (e:bool) -> (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> some_b ((M_uint16.gt x y) = e) | None -> Some false) | None -> Some false));
  gte = (fun (a:int) (b:int) (e:bool) -> (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> some_b ((M_uint16.gte x y) = e) | None -> Some false) | None -> Some false));
  lt = (fun (a:int) (b:int) (e:bool) -> (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> some_b ((M_uint16.lt x y) = e) | None -> Some false) | None -> Some false));
  lte = (fun (a:int) (b:int) (e:bool) -> (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> some_b ((M_uint16.lte x y) = e) | None -> Some false) | None -> Some false));
  eq_mask = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.eq_mask x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  gte_mask = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint16 a with Some x -> (match mk_uint16 b with Some y -> (match mk_uint16 e with Some z -> some_b (M_uint16.eq (M_uint16.gte_mask x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  to_string = (Some (fun (a:int) (s:string) -> (match mk_uint16 a with Some x -> M_uint16.to_string x = s | None -> false)));
  zero_one = (fun () -> M_uint16.eq M_uint16.zero (M_uint16.uint_to_t 0) && M_uint16.eq M_uint16.one (M_uint16.uint_to_t 1)) }

module M_uint32 = FStar.UInt32
let mk_uint32 (n:int) : option (x:M_uint32.t{M_uint32.v x == n}) = if n >= 0 && n <= 4294967295 then Some (M_uint32.uint_to_t n) else None
let ops_uint32 : ops = {
  name = "UInt32";
  bits = 32;
  signed = false;
  add_mod = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.add_mod x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub_mod = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.sub_mod x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul_mod = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.mul_mod x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  add = (Some (fun (a:int) (b:int) (e:int) -> if a + b <= 4294967295 then (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.add x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub = (Some (fun (a:int) (b:int) (e:int) -> if a - b >= 0 then (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.sub x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul = (Some (fun (a:int) (b:int) (e:int) -> if a * b <= 4294967295 then (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.mul x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  add_us = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.add_underspec x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub_us = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.sub_underspec x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul_us = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.mul_underspec x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  div = (Some (fun (a:int) (b:int) (e:int) -> if b <> 0 then (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.div x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rem = (Some (fun (a:int) (b:int) (e:int) -> if b <> 0 then (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.rem x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logand = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.logand x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logor = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.logor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logxor = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.logxor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  lognot = (Some (fun (a:int) (e:int) -> (match mk_uint32 a with Some x -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.lognot x) z) | None -> Some false) | None -> Some false)));
  shl = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 32 then (match mk_uint32 a with Some x -> (match mk32 s with Some c -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.shift_left x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  shr = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 32 then (match mk_uint32 a with Some x -> (match mk32 s with Some c -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.shift_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sar = None;
  rotl = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 32 then (match mk_uint32 a with Some x -> (match mk32 s with Some c -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.rotate_left x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rotr = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 32 then (match mk_uint32 a with Some x -> (match mk32 s with Some c -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.rotate_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  eq = (fun (a:int) (b:int) (e:bool) -> (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> some_b ((M_uint32.eq x y) = e) | None -> Some false) | None -> Some false));
  ne = (fun (a:int) (b:int) (e:bool) -> (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> some_b ((M_uint32.ne x y) = e) | None -> Some false) | None -> Some false));
  gt = (fun (a:int) (b:int) (e:bool) -> (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> some_b ((M_uint32.gt x y) = e) | None -> Some false) | None -> Some false));
  gte = (fun (a:int) (b:int) (e:bool) -> (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> some_b ((M_uint32.gte x y) = e) | None -> Some false) | None -> Some false));
  lt = (fun (a:int) (b:int) (e:bool) -> (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> some_b ((M_uint32.lt x y) = e) | None -> Some false) | None -> Some false));
  lte = (fun (a:int) (b:int) (e:bool) -> (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> some_b ((M_uint32.lte x y) = e) | None -> Some false) | None -> Some false));
  eq_mask = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.eq_mask x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  gte_mask = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint32 a with Some x -> (match mk_uint32 b with Some y -> (match mk_uint32 e with Some z -> some_b (M_uint32.eq (M_uint32.gte_mask x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  to_string = (Some (fun (a:int) (s:string) -> (match mk_uint32 a with Some x -> M_uint32.to_string x = s | None -> false)));
  zero_one = (fun () -> M_uint32.eq M_uint32.zero (M_uint32.uint_to_t 0) && M_uint32.eq M_uint32.one (M_uint32.uint_to_t 1)) }

module M_uint64 = FStar.UInt64
let mk_uint64 (n:int) : option (x:M_uint64.t{M_uint64.v x == n}) = if n >= 0 && n <= 18446744073709551615 then Some (M_uint64.uint_to_t n) else None
let ops_uint64 : ops = {
  name = "UInt64";
  bits = 64;
  signed = false;
  add_mod = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.add_mod x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub_mod = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.sub_mod x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul_mod = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.mul_mod x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  add = (Some (fun (a:int) (b:int) (e:int) -> if a + b <= 18446744073709551615 then (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.add x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub = (Some (fun (a:int) (b:int) (e:int) -> if a - b >= 0 then (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.sub x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul = (Some (fun (a:int) (b:int) (e:int) -> if a * b <= 18446744073709551615 then (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.mul x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  add_us = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.add_underspec x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub_us = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.sub_underspec x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul_us = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.mul_underspec x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  div = (Some (fun (a:int) (b:int) (e:int) -> if b <> 0 then (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.div x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rem = (Some (fun (a:int) (b:int) (e:int) -> if b <> 0 then (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.rem x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logand = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.logand x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logor = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.logor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logxor = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.logxor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  lognot = (Some (fun (a:int) (e:int) -> (match mk_uint64 a with Some x -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.lognot x) z) | None -> Some false) | None -> Some false)));
  shl = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 64 then (match mk_uint64 a with Some x -> (match mk32 s with Some c -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.shift_left x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  shr = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 64 then (match mk_uint64 a with Some x -> (match mk32 s with Some c -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.shift_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sar = None;
  rotl = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 64 then (match mk_uint64 a with Some x -> (match mk32 s with Some c -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.rotate_left x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rotr = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 64 then (match mk_uint64 a with Some x -> (match mk32 s with Some c -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.rotate_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  eq = (fun (a:int) (b:int) (e:bool) -> (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> some_b ((M_uint64.eq x y) = e) | None -> Some false) | None -> Some false));
  ne = (fun (a:int) (b:int) (e:bool) -> (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> some_b ((M_uint64.ne x y) = e) | None -> Some false) | None -> Some false));
  gt = (fun (a:int) (b:int) (e:bool) -> (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> some_b ((M_uint64.gt x y) = e) | None -> Some false) | None -> Some false));
  gte = (fun (a:int) (b:int) (e:bool) -> (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> some_b ((M_uint64.gte x y) = e) | None -> Some false) | None -> Some false));
  lt = (fun (a:int) (b:int) (e:bool) -> (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> some_b ((M_uint64.lt x y) = e) | None -> Some false) | None -> Some false));
  lte = (fun (a:int) (b:int) (e:bool) -> (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> some_b ((M_uint64.lte x y) = e) | None -> Some false) | None -> Some false));
  eq_mask = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.eq_mask x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  gte_mask = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_uint64 a with Some x -> (match mk_uint64 b with Some y -> (match mk_uint64 e with Some z -> some_b (M_uint64.eq (M_uint64.gte_mask x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  to_string = (Some (fun (a:int) (s:string) -> (match mk_uint64 a with Some x -> M_uint64.to_string x = s | None -> false)));
  zero_one = (fun () -> M_uint64.eq M_uint64.zero (M_uint64.uint_to_t 0) && M_uint64.eq M_uint64.one (M_uint64.uint_to_t 1)) }

module M_uint128 = FStar.UInt128
let mk_uint128 (n:int) : option (x:M_uint128.t{M_uint128.v x == n}) = assert_norm (pow2 128 == 340282366920938463463374607431768211456); if n >= 0 && n <= 340282366920938463463374607431768211455 then Some (M_uint128.uint_to_t n) else None
let ops_uint128 : ops = {
  name = "UInt128";
  bits = 128;
  signed = false;
  add_mod = (Some (fun (a:int) (b:int) (e:int) -> if true then (assert_norm (pow2 128 == 340282366920938463463374607431768211456); match mk_uint128 a with Some x -> (match mk_uint128 b with Some y -> (match mk_uint128 e with Some z -> some_b (M_uint128.eq (M_uint128.add_mod x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub_mod = (Some (fun (a:int) (b:int) (e:int) -> if true then (assert_norm (pow2 128 == 340282366920938463463374607431768211456); match mk_uint128 a with Some x -> (match mk_uint128 b with Some y -> (match mk_uint128 e with Some z -> some_b (M_uint128.eq (M_uint128.sub_mod x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul_mod = None;
  add = (Some (fun (a:int) (b:int) (e:int) -> if a + b <= 340282366920938463463374607431768211455 then (assert_norm (pow2 128 == 340282366920938463463374607431768211456); match mk_uint128 a with Some x -> (match mk_uint128 b with Some y -> (match mk_uint128 e with Some z -> some_b (M_uint128.eq (M_uint128.add x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub = (Some (fun (a:int) (b:int) (e:int) -> if a - b >= 0 then (assert_norm (pow2 128 == 340282366920938463463374607431768211456); match mk_uint128 a with Some x -> (match mk_uint128 b with Some y -> (match mk_uint128 e with Some z -> some_b (M_uint128.eq (M_uint128.sub x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul = None;
  add_us = (Some (fun (a:int) (b:int) (e:int) -> if true then (assert_norm (pow2 128 == 340282366920938463463374607431768211456); match mk_uint128 a with Some x -> (match mk_uint128 b with Some y -> (match mk_uint128 e with Some z -> some_b (M_uint128.eq (M_uint128.add_underspec x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub_us = (Some (fun (a:int) (b:int) (e:int) -> if true then (assert_norm (pow2 128 == 340282366920938463463374607431768211456); match mk_uint128 a with Some x -> (match mk_uint128 b with Some y -> (match mk_uint128 e with Some z -> some_b (M_uint128.eq (M_uint128.sub_underspec x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul_us = None;
  div = None;
  rem = None;
  logand = (Some (fun (a:int) (b:int) (e:int) -> if true then (assert_norm (pow2 128 == 340282366920938463463374607431768211456); match mk_uint128 a with Some x -> (match mk_uint128 b with Some y -> (match mk_uint128 e with Some z -> some_b (M_uint128.eq (M_uint128.logand x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logor = (Some (fun (a:int) (b:int) (e:int) -> if true then (assert_norm (pow2 128 == 340282366920938463463374607431768211456); match mk_uint128 a with Some x -> (match mk_uint128 b with Some y -> (match mk_uint128 e with Some z -> some_b (M_uint128.eq (M_uint128.logor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logxor = (Some (fun (a:int) (b:int) (e:int) -> if true then (assert_norm (pow2 128 == 340282366920938463463374607431768211456); match mk_uint128 a with Some x -> (match mk_uint128 b with Some y -> (match mk_uint128 e with Some z -> some_b (M_uint128.eq (M_uint128.logxor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  lognot = (Some (fun (a:int) (e:int) -> (match mk_uint128 a with Some x -> (match mk_uint128 e with Some z -> some_b (M_uint128.eq (M_uint128.lognot x) z) | None -> Some false) | None -> Some false)));
  shl = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 128 then (assert_norm (pow2 128 == 340282366920938463463374607431768211456); match mk_uint128 a with Some x -> (match mk32 s with Some c -> (match mk_uint128 e with Some z -> some_b (M_uint128.eq (M_uint128.shift_left x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  shr = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 128 then (assert_norm (pow2 128 == 340282366920938463463374607431768211456); match mk_uint128 a with Some x -> (match mk32 s with Some c -> (match mk_uint128 e with Some z -> some_b (M_uint128.eq (M_uint128.shift_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sar = None;
  rotl = None;
  rotr = None;
  eq = (fun (a:int) (b:int) (e:bool) -> (match mk_uint128 a with Some x -> (match mk_uint128 b with Some y -> some_b ((M_uint128.eq x y) = e) | None -> Some false) | None -> Some false));
  ne = (fun (a:int) (b:int) (e:bool) -> None);
  gt = (fun (a:int) (b:int) (e:bool) -> (match mk_uint128 a with Some x -> (match mk_uint128 b with Some y -> some_b ((M_uint128.gt x y) = e) | None -> Some false) | None -> Some false));
  gte = (fun (a:int) (b:int) (e:bool) -> (match mk_uint128 a with Some x -> (match mk_uint128 b with Some y -> some_b ((M_uint128.gte x y) = e) | None -> Some false) | None -> Some false));
  lt = (fun (a:int) (b:int) (e:bool) -> (match mk_uint128 a with Some x -> (match mk_uint128 b with Some y -> some_b ((M_uint128.lt x y) = e) | None -> Some false) | None -> Some false));
  lte = (fun (a:int) (b:int) (e:bool) -> (match mk_uint128 a with Some x -> (match mk_uint128 b with Some y -> some_b ((M_uint128.lte x y) = e) | None -> Some false) | None -> Some false));
  eq_mask = (Some (fun (a:int) (b:int) (e:int) -> if true then (assert_norm (pow2 128 == 340282366920938463463374607431768211456); match mk_uint128 a with Some x -> (match mk_uint128 b with Some y -> (match mk_uint128 e with Some z -> some_b (M_uint128.eq (M_uint128.eq_mask x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  gte_mask = (Some (fun (a:int) (b:int) (e:int) -> if true then (assert_norm (pow2 128 == 340282366920938463463374607431768211456); match mk_uint128 a with Some x -> (match mk_uint128 b with Some y -> (match mk_uint128 e with Some z -> some_b (M_uint128.eq (M_uint128.gte_mask x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  to_string = None;
  zero_one = (fun () -> true) }

module M_int8 = FStar.Int8
let mk_int8 (n:int) : option (x:M_int8.t{M_int8.v x == n}) = if n >= (0 - 128) && n <= 127 then Some (M_int8.int_to_t n) else None
let ops_int8 : ops = {
  name = "Int8";
  bits = 8;
  signed = true;
  add_mod = None;
  sub_mod = None;
  mul_mod = None;
  add = (Some (fun (a:int) (b:int) (e:int) -> if (a + b) >= (0 - 128) && (a + b) <= 127 then (match mk_int8 a with Some x -> (match mk_int8 b with Some y -> (match mk_int8 e with Some z -> some_b (M_int8.eq (M_int8.add x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub = (Some (fun (a:int) (b:int) (e:int) -> if (a - b) >= (0 - 128) && (a - b) <= 127 then (match mk_int8 a with Some x -> (match mk_int8 b with Some y -> (match mk_int8 e with Some z -> some_b (M_int8.eq (M_int8.sub x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul = (Some (fun (a:int) (b:int) (e:int) -> if (a * b) >= (0 - 128) && (a * b) <= 127 then (match mk_int8 a with Some x -> (match mk_int8 b with Some y -> (match mk_int8 e with Some z -> some_b (M_int8.eq (M_int8.mul x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  add_us = None;
  sub_us = None;
  mul_us = None;
  div = (Some (fun (a:int) (b:int) (e:int) -> if b <> 0 && (a <> (0 - 128) || b <> (0 - 1)) then (match mk_int8 a with Some x -> (match mk_int8 b with Some y -> (match mk_int8 e with Some z -> some_b (M_int8.eq (M_int8.div x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rem = (Some (fun (a:int) (b:int) (e:int) -> if b <> 0 && (a <> (0 - 128) || b <> (0 - 1)) then (match mk_int8 a with Some x -> (match mk_int8 b with Some y -> (match mk_int8 e with Some z -> some_b (M_int8.eq (M_int8.rem x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logand = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_int8 a with Some x -> (match mk_int8 b with Some y -> (match mk_int8 e with Some z -> some_b (M_int8.eq (M_int8.logand x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logor = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_int8 a with Some x -> (match mk_int8 b with Some y -> (match mk_int8 e with Some z -> some_b (M_int8.eq (M_int8.logor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logxor = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_int8 a with Some x -> (match mk_int8 b with Some y -> (match mk_int8 e with Some z -> some_b (M_int8.eq (M_int8.logxor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  lognot = (Some (fun (a:int) (e:int) -> (match mk_int8 a with Some x -> (match mk_int8 e with Some z -> some_b (M_int8.eq (M_int8.lognot x) z) | None -> Some false) | None -> Some false)));
  shl = (Some (fun (a:int) (s:int) (e:int) -> if a >= 0 && s >= 0 && s < 8 && a * pow2 s <= 127 then (match mk_int8 a with Some x -> (match mk32 s with Some c -> (match mk_int8 e with Some z -> some_b (M_int8.eq (M_int8.shift_left x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  shr = (Some (fun (a:int) (s:int) (e:int) -> if a >= 0 && s >= 0 && s < 8 then (match mk_int8 a with Some x -> (match mk32 s with Some c -> (match mk_int8 e with Some z -> some_b (M_int8.eq (M_int8.shift_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sar = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 8 then (match mk_int8 a with Some x -> (match mk32 s with Some c -> (match mk_int8 e with Some z -> some_b (M_int8.eq (M_int8.shift_arithmetic_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rotl = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 8 then (match mk_int8 a with Some x -> (match mk32 s with Some c -> (match mk_int8 e with Some z -> some_b (M_int8.eq (M_int8.rotate_left x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rotr = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 8 then (match mk_int8 a with Some x -> (match mk32 s with Some c -> (match mk_int8 e with Some z -> some_b (M_int8.eq (M_int8.rotate_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  eq = (fun (a:int) (b:int) (e:bool) -> (match mk_int8 a with Some x -> (match mk_int8 b with Some y -> some_b ((M_int8.eq x y) = e) | None -> Some false) | None -> Some false));
  ne = (fun (a:int) (b:int) (e:bool) -> (match mk_int8 a with Some x -> (match mk_int8 b with Some y -> some_b ((M_int8.ne x y) = e) | None -> Some false) | None -> Some false));
  gt = (fun (a:int) (b:int) (e:bool) -> (match mk_int8 a with Some x -> (match mk_int8 b with Some y -> some_b ((M_int8.gt x y) = e) | None -> Some false) | None -> Some false));
  gte = (fun (a:int) (b:int) (e:bool) -> (match mk_int8 a with Some x -> (match mk_int8 b with Some y -> some_b ((M_int8.gte x y) = e) | None -> Some false) | None -> Some false));
  lt = (fun (a:int) (b:int) (e:bool) -> (match mk_int8 a with Some x -> (match mk_int8 b with Some y -> some_b ((M_int8.lt x y) = e) | None -> Some false) | None -> Some false));
  lte = (fun (a:int) (b:int) (e:bool) -> (match mk_int8 a with Some x -> (match mk_int8 b with Some y -> some_b ((M_int8.lte x y) = e) | None -> Some false) | None -> Some false));
  eq_mask = None;
  gte_mask = None;
  to_string = (Some (fun (a:int) (s:string) -> (match mk_int8 a with Some x -> M_int8.to_string x = s | None -> false)));
  zero_one = (fun () -> M_int8.eq M_int8.zero (M_int8.int_to_t 0) && M_int8.eq M_int8.one (M_int8.int_to_t 1)) }

module M_int16 = FStar.Int16
let mk_int16 (n:int) : option (x:M_int16.t{M_int16.v x == n}) = if n >= (0 - 32768) && n <= 32767 then Some (M_int16.int_to_t n) else None
let ops_int16 : ops = {
  name = "Int16";
  bits = 16;
  signed = true;
  add_mod = None;
  sub_mod = None;
  mul_mod = None;
  add = (Some (fun (a:int) (b:int) (e:int) -> if (a + b) >= (0 - 32768) && (a + b) <= 32767 then (match mk_int16 a with Some x -> (match mk_int16 b with Some y -> (match mk_int16 e with Some z -> some_b (M_int16.eq (M_int16.add x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub = (Some (fun (a:int) (b:int) (e:int) -> if (a - b) >= (0 - 32768) && (a - b) <= 32767 then (match mk_int16 a with Some x -> (match mk_int16 b with Some y -> (match mk_int16 e with Some z -> some_b (M_int16.eq (M_int16.sub x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul = (Some (fun (a:int) (b:int) (e:int) -> if (a * b) >= (0 - 32768) && (a * b) <= 32767 then (match mk_int16 a with Some x -> (match mk_int16 b with Some y -> (match mk_int16 e with Some z -> some_b (M_int16.eq (M_int16.mul x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  add_us = None;
  sub_us = None;
  mul_us = None;
  div = (Some (fun (a:int) (b:int) (e:int) -> if b <> 0 && (a <> (0 - 32768) || b <> (0 - 1)) then (match mk_int16 a with Some x -> (match mk_int16 b with Some y -> (match mk_int16 e with Some z -> some_b (M_int16.eq (M_int16.div x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rem = (Some (fun (a:int) (b:int) (e:int) -> if b <> 0 && (a <> (0 - 32768) || b <> (0 - 1)) then (match mk_int16 a with Some x -> (match mk_int16 b with Some y -> (match mk_int16 e with Some z -> some_b (M_int16.eq (M_int16.rem x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logand = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_int16 a with Some x -> (match mk_int16 b with Some y -> (match mk_int16 e with Some z -> some_b (M_int16.eq (M_int16.logand x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logor = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_int16 a with Some x -> (match mk_int16 b with Some y -> (match mk_int16 e with Some z -> some_b (M_int16.eq (M_int16.logor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logxor = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_int16 a with Some x -> (match mk_int16 b with Some y -> (match mk_int16 e with Some z -> some_b (M_int16.eq (M_int16.logxor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  lognot = (Some (fun (a:int) (e:int) -> (match mk_int16 a with Some x -> (match mk_int16 e with Some z -> some_b (M_int16.eq (M_int16.lognot x) z) | None -> Some false) | None -> Some false)));
  shl = (Some (fun (a:int) (s:int) (e:int) -> if a >= 0 && s >= 0 && s < 16 && a * pow2 s <= 32767 then (match mk_int16 a with Some x -> (match mk32 s with Some c -> (match mk_int16 e with Some z -> some_b (M_int16.eq (M_int16.shift_left x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  shr = (Some (fun (a:int) (s:int) (e:int) -> if a >= 0 && s >= 0 && s < 16 then (match mk_int16 a with Some x -> (match mk32 s with Some c -> (match mk_int16 e with Some z -> some_b (M_int16.eq (M_int16.shift_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sar = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 16 then (match mk_int16 a with Some x -> (match mk32 s with Some c -> (match mk_int16 e with Some z -> some_b (M_int16.eq (M_int16.shift_arithmetic_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rotl = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 16 then (match mk_int16 a with Some x -> (match mk32 s with Some c -> (match mk_int16 e with Some z -> some_b (M_int16.eq (M_int16.rotate_left x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rotr = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 16 then (match mk_int16 a with Some x -> (match mk32 s with Some c -> (match mk_int16 e with Some z -> some_b (M_int16.eq (M_int16.rotate_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  eq = (fun (a:int) (b:int) (e:bool) -> (match mk_int16 a with Some x -> (match mk_int16 b with Some y -> some_b ((M_int16.eq x y) = e) | None -> Some false) | None -> Some false));
  ne = (fun (a:int) (b:int) (e:bool) -> (match mk_int16 a with Some x -> (match mk_int16 b with Some y -> some_b ((M_int16.ne x y) = e) | None -> Some false) | None -> Some false));
  gt = (fun (a:int) (b:int) (e:bool) -> (match mk_int16 a with Some x -> (match mk_int16 b with Some y -> some_b ((M_int16.gt x y) = e) | None -> Some false) | None -> Some false));
  gte = (fun (a:int) (b:int) (e:bool) -> (match mk_int16 a with Some x -> (match mk_int16 b with Some y -> some_b ((M_int16.gte x y) = e) | None -> Some false) | None -> Some false));
  lt = (fun (a:int) (b:int) (e:bool) -> (match mk_int16 a with Some x -> (match mk_int16 b with Some y -> some_b ((M_int16.lt x y) = e) | None -> Some false) | None -> Some false));
  lte = (fun (a:int) (b:int) (e:bool) -> (match mk_int16 a with Some x -> (match mk_int16 b with Some y -> some_b ((M_int16.lte x y) = e) | None -> Some false) | None -> Some false));
  eq_mask = None;
  gte_mask = None;
  to_string = (Some (fun (a:int) (s:string) -> (match mk_int16 a with Some x -> M_int16.to_string x = s | None -> false)));
  zero_one = (fun () -> M_int16.eq M_int16.zero (M_int16.int_to_t 0) && M_int16.eq M_int16.one (M_int16.int_to_t 1)) }

module M_int32 = FStar.Int32
let mk_int32 (n:int) : option (x:M_int32.t{M_int32.v x == n}) = if n >= (0 - 2147483648) && n <= 2147483647 then Some (M_int32.int_to_t n) else None
let ops_int32 : ops = {
  name = "Int32";
  bits = 32;
  signed = true;
  add_mod = None;
  sub_mod = None;
  mul_mod = None;
  add = (Some (fun (a:int) (b:int) (e:int) -> if (a + b) >= (0 - 2147483648) && (a + b) <= 2147483647 then (match mk_int32 a with Some x -> (match mk_int32 b with Some y -> (match mk_int32 e with Some z -> some_b (M_int32.eq (M_int32.add x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub = (Some (fun (a:int) (b:int) (e:int) -> if (a - b) >= (0 - 2147483648) && (a - b) <= 2147483647 then (match mk_int32 a with Some x -> (match mk_int32 b with Some y -> (match mk_int32 e with Some z -> some_b (M_int32.eq (M_int32.sub x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul = (Some (fun (a:int) (b:int) (e:int) -> if (a * b) >= (0 - 2147483648) && (a * b) <= 2147483647 then (match mk_int32 a with Some x -> (match mk_int32 b with Some y -> (match mk_int32 e with Some z -> some_b (M_int32.eq (M_int32.mul x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  add_us = None;
  sub_us = None;
  mul_us = None;
  div = (Some (fun (a:int) (b:int) (e:int) -> if b <> 0 && (a <> (0 - 2147483648) || b <> (0 - 1)) then (match mk_int32 a with Some x -> (match mk_int32 b with Some y -> (match mk_int32 e with Some z -> some_b (M_int32.eq (M_int32.div x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rem = (Some (fun (a:int) (b:int) (e:int) -> if b <> 0 && (a <> (0 - 2147483648) || b <> (0 - 1)) then (match mk_int32 a with Some x -> (match mk_int32 b with Some y -> (match mk_int32 e with Some z -> some_b (M_int32.eq (M_int32.rem x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logand = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_int32 a with Some x -> (match mk_int32 b with Some y -> (match mk_int32 e with Some z -> some_b (M_int32.eq (M_int32.logand x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logor = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_int32 a with Some x -> (match mk_int32 b with Some y -> (match mk_int32 e with Some z -> some_b (M_int32.eq (M_int32.logor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logxor = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_int32 a with Some x -> (match mk_int32 b with Some y -> (match mk_int32 e with Some z -> some_b (M_int32.eq (M_int32.logxor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  lognot = (Some (fun (a:int) (e:int) -> (match mk_int32 a with Some x -> (match mk_int32 e with Some z -> some_b (M_int32.eq (M_int32.lognot x) z) | None -> Some false) | None -> Some false)));
  shl = (Some (fun (a:int) (s:int) (e:int) -> if a >= 0 && s >= 0 && s < 32 && a * pow2 s <= 2147483647 then (match mk_int32 a with Some x -> (match mk32 s with Some c -> (match mk_int32 e with Some z -> some_b (M_int32.eq (M_int32.shift_left x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  shr = (Some (fun (a:int) (s:int) (e:int) -> if a >= 0 && s >= 0 && s < 32 then (match mk_int32 a with Some x -> (match mk32 s with Some c -> (match mk_int32 e with Some z -> some_b (M_int32.eq (M_int32.shift_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sar = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 32 then (match mk_int32 a with Some x -> (match mk32 s with Some c -> (match mk_int32 e with Some z -> some_b (M_int32.eq (M_int32.shift_arithmetic_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rotl = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 32 then (match mk_int32 a with Some x -> (match mk32 s with Some c -> (match mk_int32 e with Some z -> some_b (M_int32.eq (M_int32.rotate_left x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rotr = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 32 then (match mk_int32 a with Some x -> (match mk32 s with Some c -> (match mk_int32 e with Some z -> some_b (M_int32.eq (M_int32.rotate_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  eq = (fun (a:int) (b:int) (e:bool) -> (match mk_int32 a with Some x -> (match mk_int32 b with Some y -> some_b ((M_int32.eq x y) = e) | None -> Some false) | None -> Some false));
  ne = (fun (a:int) (b:int) (e:bool) -> (match mk_int32 a with Some x -> (match mk_int32 b with Some y -> some_b ((M_int32.ne x y) = e) | None -> Some false) | None -> Some false));
  gt = (fun (a:int) (b:int) (e:bool) -> (match mk_int32 a with Some x -> (match mk_int32 b with Some y -> some_b ((M_int32.gt x y) = e) | None -> Some false) | None -> Some false));
  gte = (fun (a:int) (b:int) (e:bool) -> (match mk_int32 a with Some x -> (match mk_int32 b with Some y -> some_b ((M_int32.gte x y) = e) | None -> Some false) | None -> Some false));
  lt = (fun (a:int) (b:int) (e:bool) -> (match mk_int32 a with Some x -> (match mk_int32 b with Some y -> some_b ((M_int32.lt x y) = e) | None -> Some false) | None -> Some false));
  lte = (fun (a:int) (b:int) (e:bool) -> (match mk_int32 a with Some x -> (match mk_int32 b with Some y -> some_b ((M_int32.lte x y) = e) | None -> Some false) | None -> Some false));
  eq_mask = None;
  gte_mask = None;
  to_string = (Some (fun (a:int) (s:string) -> (match mk_int32 a with Some x -> M_int32.to_string x = s | None -> false)));
  zero_one = (fun () -> M_int32.eq M_int32.zero (M_int32.int_to_t 0) && M_int32.eq M_int32.one (M_int32.int_to_t 1)) }

module M_int64 = FStar.Int64
let mk_int64 (n:int) : option (x:M_int64.t{M_int64.v x == n}) = if n >= (0 - 9223372036854775808) && n <= 9223372036854775807 then Some (M_int64.int_to_t n) else None
let ops_int64 : ops = {
  name = "Int64";
  bits = 64;
  signed = true;
  add_mod = None;
  sub_mod = None;
  mul_mod = None;
  add = (Some (fun (a:int) (b:int) (e:int) -> if (a + b) >= (0 - 9223372036854775808) && (a + b) <= 9223372036854775807 then (match mk_int64 a with Some x -> (match mk_int64 b with Some y -> (match mk_int64 e with Some z -> some_b (M_int64.eq (M_int64.add x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub = (Some (fun (a:int) (b:int) (e:int) -> if (a - b) >= (0 - 9223372036854775808) && (a - b) <= 9223372036854775807 then (match mk_int64 a with Some x -> (match mk_int64 b with Some y -> (match mk_int64 e with Some z -> some_b (M_int64.eq (M_int64.sub x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul = (Some (fun (a:int) (b:int) (e:int) -> if (a * b) >= (0 - 9223372036854775808) && (a * b) <= 9223372036854775807 then (match mk_int64 a with Some x -> (match mk_int64 b with Some y -> (match mk_int64 e with Some z -> some_b (M_int64.eq (M_int64.mul x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  add_us = None;
  sub_us = None;
  mul_us = None;
  div = (Some (fun (a:int) (b:int) (e:int) -> if b <> 0 && (a <> (0 - 9223372036854775808) || b <> (0 - 1)) then (match mk_int64 a with Some x -> (match mk_int64 b with Some y -> (match mk_int64 e with Some z -> some_b (M_int64.eq (M_int64.div x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rem = (Some (fun (a:int) (b:int) (e:int) -> if b <> 0 && (a <> (0 - 9223372036854775808) || b <> (0 - 1)) then (match mk_int64 a with Some x -> (match mk_int64 b with Some y -> (match mk_int64 e with Some z -> some_b (M_int64.eq (M_int64.rem x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logand = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_int64 a with Some x -> (match mk_int64 b with Some y -> (match mk_int64 e with Some z -> some_b (M_int64.eq (M_int64.logand x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logor = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_int64 a with Some x -> (match mk_int64 b with Some y -> (match mk_int64 e with Some z -> some_b (M_int64.eq (M_int64.logor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logxor = (Some (fun (a:int) (b:int) (e:int) -> if true then (match mk_int64 a with Some x -> (match mk_int64 b with Some y -> (match mk_int64 e with Some z -> some_b (M_int64.eq (M_int64.logxor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  lognot = (Some (fun (a:int) (e:int) -> (match mk_int64 a with Some x -> (match mk_int64 e with Some z -> some_b (M_int64.eq (M_int64.lognot x) z) | None -> Some false) | None -> Some false)));
  shl = (Some (fun (a:int) (s:int) (e:int) -> if a >= 0 && s >= 0 && s < 64 && a * pow2 s <= 9223372036854775807 then (match mk_int64 a with Some x -> (match mk32 s with Some c -> (match mk_int64 e with Some z -> some_b (M_int64.eq (M_int64.shift_left x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  shr = (Some (fun (a:int) (s:int) (e:int) -> if a >= 0 && s >= 0 && s < 64 then (match mk_int64 a with Some x -> (match mk32 s with Some c -> (match mk_int64 e with Some z -> some_b (M_int64.eq (M_int64.shift_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sar = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 64 then (match mk_int64 a with Some x -> (match mk32 s with Some c -> (match mk_int64 e with Some z -> some_b (M_int64.eq (M_int64.shift_arithmetic_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rotl = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 64 then (match mk_int64 a with Some x -> (match mk32 s with Some c -> (match mk_int64 e with Some z -> some_b (M_int64.eq (M_int64.rotate_left x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rotr = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 64 then (match mk_int64 a with Some x -> (match mk32 s with Some c -> (match mk_int64 e with Some z -> some_b (M_int64.eq (M_int64.rotate_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  eq = (fun (a:int) (b:int) (e:bool) -> (match mk_int64 a with Some x -> (match mk_int64 b with Some y -> some_b ((M_int64.eq x y) = e) | None -> Some false) | None -> Some false));
  ne = (fun (a:int) (b:int) (e:bool) -> (match mk_int64 a with Some x -> (match mk_int64 b with Some y -> some_b ((M_int64.ne x y) = e) | None -> Some false) | None -> Some false));
  gt = (fun (a:int) (b:int) (e:bool) -> (match mk_int64 a with Some x -> (match mk_int64 b with Some y -> some_b ((M_int64.gt x y) = e) | None -> Some false) | None -> Some false));
  gte = (fun (a:int) (b:int) (e:bool) -> (match mk_int64 a with Some x -> (match mk_int64 b with Some y -> some_b ((M_int64.gte x y) = e) | None -> Some false) | None -> Some false));
  lt = (fun (a:int) (b:int) (e:bool) -> (match mk_int64 a with Some x -> (match mk_int64 b with Some y -> some_b ((M_int64.lt x y) = e) | None -> Some false) | None -> Some false));
  lte = (fun (a:int) (b:int) (e:bool) -> (match mk_int64 a with Some x -> (match mk_int64 b with Some y -> some_b ((M_int64.lte x y) = e) | None -> Some false) | None -> Some false));
  eq_mask = None;
  gte_mask = None;
  to_string = (Some (fun (a:int) (s:string) -> (match mk_int64 a with Some x -> M_int64.to_string x = s | None -> false)));
  zero_one = (fun () -> M_int64.eq M_int64.zero (M_int64.int_to_t 0) && M_int64.eq M_int64.one (M_int64.int_to_t 1)) }

module M_int128 = FStar.Int128
let mk_int128 (n:int) : option (x:M_int128.t{M_int128.v x == n}) = assert_norm (pow2 127 == 170141183460469231731687303715884105728); if n >= (0 - 170141183460469231731687303715884105728) && n <= 170141183460469231731687303715884105727 then Some (M_int128.int_to_t n) else None
let ops_int128 : ops = {
  name = "Int128";
  bits = 128;
  signed = true;
  add_mod = None;
  sub_mod = None;
  mul_mod = None;
  add = (Some (fun (a:int) (b:int) (e:int) -> if (a + b) >= (0 - 170141183460469231731687303715884105728) && (a + b) <= 170141183460469231731687303715884105727 then (assert_norm (pow2 127 == 170141183460469231731687303715884105728); match mk_int128 a with Some x -> (match mk_int128 b with Some y -> (match mk_int128 e with Some z -> some_b (M_int128.eq (M_int128.add x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sub = (Some (fun (a:int) (b:int) (e:int) -> if (a - b) >= (0 - 170141183460469231731687303715884105728) && (a - b) <= 170141183460469231731687303715884105727 then (assert_norm (pow2 127 == 170141183460469231731687303715884105728); match mk_int128 a with Some x -> (match mk_int128 b with Some y -> (match mk_int128 e with Some z -> some_b (M_int128.eq (M_int128.sub x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  mul = (Some (fun (a:int) (b:int) (e:int) -> if (a * b) >= (0 - 170141183460469231731687303715884105728) && (a * b) <= 170141183460469231731687303715884105727 then (assert_norm (pow2 127 == 170141183460469231731687303715884105728); match mk_int128 a with Some x -> (match mk_int128 b with Some y -> (match mk_int128 e with Some z -> some_b (M_int128.eq (M_int128.mul x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  add_us = None;
  sub_us = None;
  mul_us = None;
  div = (Some (fun (a:int) (b:int) (e:int) -> if b <> 0 && (a <> (0 - 170141183460469231731687303715884105728) || b <> (0 - 1)) then (assert_norm (pow2 127 == 170141183460469231731687303715884105728); match mk_int128 a with Some x -> (match mk_int128 b with Some y -> (match mk_int128 e with Some z -> some_b (M_int128.eq (M_int128.div x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rem = (Some (fun (a:int) (b:int) (e:int) -> if b <> 0 && (a <> (0 - 170141183460469231731687303715884105728) || b <> (0 - 1)) then (assert_norm (pow2 127 == 170141183460469231731687303715884105728); match mk_int128 a with Some x -> (match mk_int128 b with Some y -> (match mk_int128 e with Some z -> some_b (M_int128.eq (M_int128.rem x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logand = (Some (fun (a:int) (b:int) (e:int) -> if true then (assert_norm (pow2 127 == 170141183460469231731687303715884105728); match mk_int128 a with Some x -> (match mk_int128 b with Some y -> (match mk_int128 e with Some z -> some_b (M_int128.eq (M_int128.logand x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logor = (Some (fun (a:int) (b:int) (e:int) -> if true then (assert_norm (pow2 127 == 170141183460469231731687303715884105728); match mk_int128 a with Some x -> (match mk_int128 b with Some y -> (match mk_int128 e with Some z -> some_b (M_int128.eq (M_int128.logor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  logxor = (Some (fun (a:int) (b:int) (e:int) -> if true then (assert_norm (pow2 127 == 170141183460469231731687303715884105728); match mk_int128 a with Some x -> (match mk_int128 b with Some y -> (match mk_int128 e with Some z -> some_b (M_int128.eq (M_int128.logxor x y) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  lognot = (Some (fun (a:int) (e:int) -> (match mk_int128 a with Some x -> (match mk_int128 e with Some z -> some_b (M_int128.eq (M_int128.lognot x) z) | None -> Some false) | None -> Some false)));
  shl = (Some (fun (a:int) (s:int) (e:int) -> if a >= 0 && s >= 0 && s < 128 && a * pow2 s <= 170141183460469231731687303715884105727 then (assert_norm (pow2 127 == 170141183460469231731687303715884105728); match mk_int128 a with Some x -> (match mk32 s with Some c -> (match mk_int128 e with Some z -> some_b (M_int128.eq (M_int128.shift_left x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  shr = (Some (fun (a:int) (s:int) (e:int) -> if a >= 0 && s >= 0 && s < 128 then (assert_norm (pow2 127 == 170141183460469231731687303715884105728); match mk_int128 a with Some x -> (match mk32 s with Some c -> (match mk_int128 e with Some z -> some_b (M_int128.eq (M_int128.shift_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  sar = (Some (fun (a:int) (s:int) (e:int) -> if s >= 0 && s < 128 then (assert_norm (pow2 127 == 170141183460469231731687303715884105728); match mk_int128 a with Some x -> (match mk32 s with Some c -> (match mk_int128 e with Some z -> some_b (M_int128.eq (M_int128.shift_arithmetic_right x c) z) | None -> Some false) | None -> Some false) | None -> Some false) else None));
  rotl = None;
  rotr = None;
  eq = (fun (a:int) (b:int) (e:bool) -> (match mk_int128 a with Some x -> (match mk_int128 b with Some y -> some_b ((M_int128.eq x y) = e) | None -> Some false) | None -> Some false));
  ne = (fun (a:int) (b:int) (e:bool) -> (match mk_int128 a with Some x -> (match mk_int128 b with Some y -> some_b ((M_int128.ne x y) = e) | None -> Some false) | None -> Some false));
  gt = (fun (a:int) (b:int) (e:bool) -> (match mk_int128 a with Some x -> (match mk_int128 b with Some y -> some_b ((M_int128.gt x y) = e) | None -> Some false) | None -> Some false));
  gte = (fun (a:int) (b:int) (e:bool) -> (match mk_int128 a with Some x -> (match mk_int128 b with Some y -> some_b ((M_int128.gte x y) = e) | None -> Some false) | None -> Some false));
  lt = (fun (a:int) (b:int) (e:bool) -> (match mk_int128 a with Some x -> (match mk_int128 b with Some y -> some_b ((M_int128.lt x y) = e) | None -> Some false) | None -> Some false));
  lte = (fun (a:int) (b:int) (e:bool) -> (match mk_int128 a with Some x -> (match mk_int128 b with Some y -> some_b ((M_int128.lte x y) = e) | None -> Some false) | None -> Some false));
  eq_mask = None;
  gte_mask = None;
  to_string = None;
  zero_one = (fun () -> M_int128.eq M_int128.zero (M_int128.int_to_t 0) && M_int128.eq M_int128.one (M_int128.int_to_t 1)) }

let cast_oracle (fb:nat) (tb:nat) (ts:bool) (a:int) : int =
  let m = if fb > tb then fb else tb in
  of_u tb ts ((if a < 0 then a + pw m else a) % pw tb)

let cast_case (fb:nat) (fs:bool) (tb:nat) (ts:bool) (name:string) (f:int -> int -> bool) : ML unit =
  List.iter (fun (a:int) -> check name (f a (cast_oracle fb tb ts a))) (operands fb fs)

let run_casts () : ML unit =
  cast_case 16 true 32 true "FStar.Int.Cast.int16_to_int32" (fun (a:int) (e:int) -> match mk_int16 a with Some x -> (match mk_int32 e with Some y -> M_int32.eq (FStar.Int.Cast.int16_to_int32 x) y | None -> false) | None -> false);
  cast_case 16 true 64 true "FStar.Int.Cast.int16_to_int64" (fun (a:int) (e:int) -> match mk_int16 a with Some x -> (match mk_int64 e with Some y -> M_int64.eq (FStar.Int.Cast.int16_to_int64 x) y | None -> false) | None -> false);
  cast_case 16 true 8 true "FStar.Int.Cast.int16_to_int8" (fun (a:int) (e:int) -> match mk_int16 a with Some x -> (match mk_int8 e with Some y -> M_int8.eq (FStar.Int.Cast.int16_to_int8 x) y | None -> false) | None -> false);
  cast_case 16 true 16 false "FStar.Int.Cast.int16_to_uint16" (fun (a:int) (e:int) -> match mk_int16 a with Some x -> (match mk_uint16 e with Some y -> M_uint16.eq (FStar.Int.Cast.int16_to_uint16 x) y | None -> false) | None -> false);
  cast_case 16 true 32 false "FStar.Int.Cast.int16_to_uint32" (fun (a:int) (e:int) -> match mk_int16 a with Some x -> (match mk_uint32 e with Some y -> M_uint32.eq (FStar.Int.Cast.int16_to_uint32 x) y | None -> false) | None -> false);
  cast_case 16 true 64 false "FStar.Int.Cast.int16_to_uint64" (fun (a:int) (e:int) -> match mk_int16 a with Some x -> (match mk_uint64 e with Some y -> M_uint64.eq (FStar.Int.Cast.int16_to_uint64 x) y | None -> false) | None -> false);
  cast_case 16 true 8 false "FStar.Int.Cast.int16_to_uint8" (fun (a:int) (e:int) -> match mk_int16 a with Some x -> (match mk_uint8 e with Some y -> M_uint8.eq (FStar.Int.Cast.int16_to_uint8 x) y | None -> false) | None -> false);
  cast_case 32 true 16 true "FStar.Int.Cast.int32_to_int16" (fun (a:int) (e:int) -> match mk_int32 a with Some x -> (match mk_int16 e with Some y -> M_int16.eq (FStar.Int.Cast.int32_to_int16 x) y | None -> false) | None -> false);
  cast_case 32 true 64 true "FStar.Int.Cast.int32_to_int64" (fun (a:int) (e:int) -> match mk_int32 a with Some x -> (match mk_int64 e with Some y -> M_int64.eq (FStar.Int.Cast.int32_to_int64 x) y | None -> false) | None -> false);
  cast_case 32 true 8 true "FStar.Int.Cast.int32_to_int8" (fun (a:int) (e:int) -> match mk_int32 a with Some x -> (match mk_int8 e with Some y -> M_int8.eq (FStar.Int.Cast.int32_to_int8 x) y | None -> false) | None -> false);
  cast_case 32 true 16 false "FStar.Int.Cast.int32_to_uint16" (fun (a:int) (e:int) -> match mk_int32 a with Some x -> (match mk_uint16 e with Some y -> M_uint16.eq (FStar.Int.Cast.int32_to_uint16 x) y | None -> false) | None -> false);
  cast_case 32 true 32 false "FStar.Int.Cast.int32_to_uint32" (fun (a:int) (e:int) -> match mk_int32 a with Some x -> (match mk_uint32 e with Some y -> M_uint32.eq (FStar.Int.Cast.int32_to_uint32 x) y | None -> false) | None -> false);
  cast_case 32 true 64 false "FStar.Int.Cast.int32_to_uint64" (fun (a:int) (e:int) -> match mk_int32 a with Some x -> (match mk_uint64 e with Some y -> M_uint64.eq (FStar.Int.Cast.int32_to_uint64 x) y | None -> false) | None -> false);
  cast_case 32 true 8 false "FStar.Int.Cast.int32_to_uint8" (fun (a:int) (e:int) -> match mk_int32 a with Some x -> (match mk_uint8 e with Some y -> M_uint8.eq (FStar.Int.Cast.int32_to_uint8 x) y | None -> false) | None -> false);
  cast_case 64 true 16 true "FStar.Int.Cast.int64_to_int16" (fun (a:int) (e:int) -> match mk_int64 a with Some x -> (match mk_int16 e with Some y -> M_int16.eq (FStar.Int.Cast.int64_to_int16 x) y | None -> false) | None -> false);
  cast_case 64 true 32 true "FStar.Int.Cast.int64_to_int32" (fun (a:int) (e:int) -> match mk_int64 a with Some x -> (match mk_int32 e with Some y -> M_int32.eq (FStar.Int.Cast.int64_to_int32 x) y | None -> false) | None -> false);
  cast_case 64 true 8 true "FStar.Int.Cast.int64_to_int8" (fun (a:int) (e:int) -> match mk_int64 a with Some x -> (match mk_int8 e with Some y -> M_int8.eq (FStar.Int.Cast.int64_to_int8 x) y | None -> false) | None -> false);
  cast_case 64 true 16 false "FStar.Int.Cast.int64_to_uint16" (fun (a:int) (e:int) -> match mk_int64 a with Some x -> (match mk_uint16 e with Some y -> M_uint16.eq (FStar.Int.Cast.int64_to_uint16 x) y | None -> false) | None -> false);
  cast_case 64 true 32 false "FStar.Int.Cast.int64_to_uint32" (fun (a:int) (e:int) -> match mk_int64 a with Some x -> (match mk_uint32 e with Some y -> M_uint32.eq (FStar.Int.Cast.int64_to_uint32 x) y | None -> false) | None -> false);
  cast_case 64 true 64 false "FStar.Int.Cast.int64_to_uint64" (fun (a:int) (e:int) -> match mk_int64 a with Some x -> (match mk_uint64 e with Some y -> M_uint64.eq (FStar.Int.Cast.int64_to_uint64 x) y | None -> false) | None -> false);
  cast_case 64 true 8 false "FStar.Int.Cast.int64_to_uint8" (fun (a:int) (e:int) -> match mk_int64 a with Some x -> (match mk_uint8 e with Some y -> M_uint8.eq (FStar.Int.Cast.int64_to_uint8 x) y | None -> false) | None -> false);
  cast_case 8 true 16 true "FStar.Int.Cast.int8_to_int16" (fun (a:int) (e:int) -> match mk_int8 a with Some x -> (match mk_int16 e with Some y -> M_int16.eq (FStar.Int.Cast.int8_to_int16 x) y | None -> false) | None -> false);
  cast_case 8 true 32 true "FStar.Int.Cast.int8_to_int32" (fun (a:int) (e:int) -> match mk_int8 a with Some x -> (match mk_int32 e with Some y -> M_int32.eq (FStar.Int.Cast.int8_to_int32 x) y | None -> false) | None -> false);
  cast_case 8 true 64 true "FStar.Int.Cast.int8_to_int64" (fun (a:int) (e:int) -> match mk_int8 a with Some x -> (match mk_int64 e with Some y -> M_int64.eq (FStar.Int.Cast.int8_to_int64 x) y | None -> false) | None -> false);
  cast_case 8 true 16 false "FStar.Int.Cast.int8_to_uint16" (fun (a:int) (e:int) -> match mk_int8 a with Some x -> (match mk_uint16 e with Some y -> M_uint16.eq (FStar.Int.Cast.int8_to_uint16 x) y | None -> false) | None -> false);
  cast_case 8 true 32 false "FStar.Int.Cast.int8_to_uint32" (fun (a:int) (e:int) -> match mk_int8 a with Some x -> (match mk_uint32 e with Some y -> M_uint32.eq (FStar.Int.Cast.int8_to_uint32 x) y | None -> false) | None -> false);
  cast_case 8 true 64 false "FStar.Int.Cast.int8_to_uint64" (fun (a:int) (e:int) -> match mk_int8 a with Some x -> (match mk_uint64 e with Some y -> M_uint64.eq (FStar.Int.Cast.int8_to_uint64 x) y | None -> false) | None -> false);
  cast_case 8 true 8 false "FStar.Int.Cast.int8_to_uint8" (fun (a:int) (e:int) -> match mk_int8 a with Some x -> (match mk_uint8 e with Some y -> M_uint8.eq (FStar.Int.Cast.int8_to_uint8 x) y | None -> false) | None -> false);
  cast_case 16 false 16 true "FStar.Int.Cast.uint16_to_int16" (fun (a:int) (e:int) -> match mk_uint16 a with Some x -> (match mk_int16 e with Some y -> M_int16.eq (FStar.Int.Cast.uint16_to_int16 x) y | None -> false) | None -> false);
  cast_case 16 false 32 true "FStar.Int.Cast.uint16_to_int32" (fun (a:int) (e:int) -> match mk_uint16 a with Some x -> (match mk_int32 e with Some y -> M_int32.eq (FStar.Int.Cast.uint16_to_int32 x) y | None -> false) | None -> false);
  cast_case 16 false 64 true "FStar.Int.Cast.uint16_to_int64" (fun (a:int) (e:int) -> match mk_uint16 a with Some x -> (match mk_int64 e with Some y -> M_int64.eq (FStar.Int.Cast.uint16_to_int64 x) y | None -> false) | None -> false);
  cast_case 16 false 8 true "FStar.Int.Cast.uint16_to_int8" (fun (a:int) (e:int) -> match mk_uint16 a with Some x -> (match mk_int8 e with Some y -> M_int8.eq (FStar.Int.Cast.uint16_to_int8 x) y | None -> false) | None -> false);
  cast_case 16 false 32 false "FStar.Int.Cast.uint16_to_uint32" (fun (a:int) (e:int) -> match mk_uint16 a with Some x -> (match mk_uint32 e with Some y -> M_uint32.eq (FStar.Int.Cast.uint16_to_uint32 x) y | None -> false) | None -> false);
  cast_case 16 false 64 false "FStar.Int.Cast.uint16_to_uint64" (fun (a:int) (e:int) -> match mk_uint16 a with Some x -> (match mk_uint64 e with Some y -> M_uint64.eq (FStar.Int.Cast.uint16_to_uint64 x) y | None -> false) | None -> false);
  cast_case 16 false 8 false "FStar.Int.Cast.uint16_to_uint8" (fun (a:int) (e:int) -> match mk_uint16 a with Some x -> (match mk_uint8 e with Some y -> M_uint8.eq (FStar.Int.Cast.uint16_to_uint8 x) y | None -> false) | None -> false);
  cast_case 32 false 16 true "FStar.Int.Cast.uint32_to_int16" (fun (a:int) (e:int) -> match mk_uint32 a with Some x -> (match mk_int16 e with Some y -> M_int16.eq (FStar.Int.Cast.uint32_to_int16 x) y | None -> false) | None -> false);
  cast_case 32 false 32 true "FStar.Int.Cast.uint32_to_int32" (fun (a:int) (e:int) -> match mk_uint32 a with Some x -> (match mk_int32 e with Some y -> M_int32.eq (FStar.Int.Cast.uint32_to_int32 x) y | None -> false) | None -> false);
  cast_case 32 false 64 true "FStar.Int.Cast.uint32_to_int64" (fun (a:int) (e:int) -> match mk_uint32 a with Some x -> (match mk_int64 e with Some y -> M_int64.eq (FStar.Int.Cast.uint32_to_int64 x) y | None -> false) | None -> false);
  cast_case 32 false 8 true "FStar.Int.Cast.uint32_to_int8" (fun (a:int) (e:int) -> match mk_uint32 a with Some x -> (match mk_int8 e with Some y -> M_int8.eq (FStar.Int.Cast.uint32_to_int8 x) y | None -> false) | None -> false);
  cast_case 32 false 16 false "FStar.Int.Cast.uint32_to_uint16" (fun (a:int) (e:int) -> match mk_uint32 a with Some x -> (match mk_uint16 e with Some y -> M_uint16.eq (FStar.Int.Cast.uint32_to_uint16 x) y | None -> false) | None -> false);
  cast_case 32 false 64 false "FStar.Int.Cast.uint32_to_uint64" (fun (a:int) (e:int) -> match mk_uint32 a with Some x -> (match mk_uint64 e with Some y -> M_uint64.eq (FStar.Int.Cast.uint32_to_uint64 x) y | None -> false) | None -> false);
  cast_case 32 false 8 false "FStar.Int.Cast.uint32_to_uint8" (fun (a:int) (e:int) -> match mk_uint32 a with Some x -> (match mk_uint8 e with Some y -> M_uint8.eq (FStar.Int.Cast.uint32_to_uint8 x) y | None -> false) | None -> false);
  cast_case 64 false 16 true "FStar.Int.Cast.uint64_to_int16" (fun (a:int) (e:int) -> match mk_uint64 a with Some x -> (match mk_int16 e with Some y -> M_int16.eq (FStar.Int.Cast.uint64_to_int16 x) y | None -> false) | None -> false);
  cast_case 64 false 32 true "FStar.Int.Cast.uint64_to_int32" (fun (a:int) (e:int) -> match mk_uint64 a with Some x -> (match mk_int32 e with Some y -> M_int32.eq (FStar.Int.Cast.uint64_to_int32 x) y | None -> false) | None -> false);
  cast_case 64 false 64 true "FStar.Int.Cast.uint64_to_int64" (fun (a:int) (e:int) -> match mk_uint64 a with Some x -> (match mk_int64 e with Some y -> M_int64.eq (FStar.Int.Cast.uint64_to_int64 x) y | None -> false) | None -> false);
  cast_case 64 false 8 true "FStar.Int.Cast.uint64_to_int8" (fun (a:int) (e:int) -> match mk_uint64 a with Some x -> (match mk_int8 e with Some y -> M_int8.eq (FStar.Int.Cast.uint64_to_int8 x) y | None -> false) | None -> false);
  cast_case 64 false 16 false "FStar.Int.Cast.uint64_to_uint16" (fun (a:int) (e:int) -> match mk_uint64 a with Some x -> (match mk_uint16 e with Some y -> M_uint16.eq (FStar.Int.Cast.uint64_to_uint16 x) y | None -> false) | None -> false);
  cast_case 64 false 32 false "FStar.Int.Cast.uint64_to_uint32" (fun (a:int) (e:int) -> match mk_uint64 a with Some x -> (match mk_uint32 e with Some y -> M_uint32.eq (FStar.Int.Cast.uint64_to_uint32 x) y | None -> false) | None -> false);
  cast_case 64 false 8 false "FStar.Int.Cast.uint64_to_uint8" (fun (a:int) (e:int) -> match mk_uint64 a with Some x -> (match mk_uint8 e with Some y -> M_uint8.eq (FStar.Int.Cast.uint64_to_uint8 x) y | None -> false) | None -> false);
  cast_case 8 false 16 true "FStar.Int.Cast.uint8_to_int16" (fun (a:int) (e:int) -> match mk_uint8 a with Some x -> (match mk_int16 e with Some y -> M_int16.eq (FStar.Int.Cast.uint8_to_int16 x) y | None -> false) | None -> false);
  cast_case 8 false 32 true "FStar.Int.Cast.uint8_to_int32" (fun (a:int) (e:int) -> match mk_uint8 a with Some x -> (match mk_int32 e with Some y -> M_int32.eq (FStar.Int.Cast.uint8_to_int32 x) y | None -> false) | None -> false);
  cast_case 8 false 64 true "FStar.Int.Cast.uint8_to_int64" (fun (a:int) (e:int) -> match mk_uint8 a with Some x -> (match mk_int64 e with Some y -> M_int64.eq (FStar.Int.Cast.uint8_to_int64 x) y | None -> false) | None -> false);
  cast_case 8 false 8 true "FStar.Int.Cast.uint8_to_int8" (fun (a:int) (e:int) -> match mk_uint8 a with Some x -> (match mk_int8 e with Some y -> M_int8.eq (FStar.Int.Cast.uint8_to_int8 x) y | None -> false) | None -> false);
  cast_case 8 false 16 false "FStar.Int.Cast.uint8_to_uint16" (fun (a:int) (e:int) -> match mk_uint8 a with Some x -> (match mk_uint16 e with Some y -> M_uint16.eq (FStar.Int.Cast.uint8_to_uint16 x) y | None -> false) | None -> false);
  cast_case 8 false 32 false "FStar.Int.Cast.uint8_to_uint32" (fun (a:int) (e:int) -> match mk_uint8 a with Some x -> (match mk_uint32 e with Some y -> M_uint32.eq (FStar.Int.Cast.uint8_to_uint32 x) y | None -> false) | None -> false);
  cast_case 8 false 64 false "FStar.Int.Cast.uint8_to_uint64" (fun (a:int) (e:int) -> match mk_uint8 a with Some x -> (match mk_uint64 e with Some y -> M_uint64.eq (FStar.Int.Cast.uint8_to_uint64 x) y | None -> false) | None -> false);
  cast_case 128 false 64 false "FStar.Int.Cast.Full.uint128_to_uint64" (fun (a:int) (e:int) -> match mk_uint128 a with Some x -> (match mk_uint64 e with Some y -> M_uint64.eq (FStar.Int.Cast.Full.uint128_to_uint64 x) y | None -> false) | None -> false);
  cast_case 64 false 128 false "FStar.Int.Cast.Full.uint64_to_uint128" (fun (a:int) (e:int) -> match mk_uint64 a with Some x -> (match mk_uint128 e with Some y -> M_uint128.eq (FStar.Int.Cast.Full.uint64_to_uint128 x) y | None -> false) | None -> false);
  ()

let run () : ML unit =
  run_ops ops_uint8;
  run_ops ops_uint16;
  run_ops ops_uint32;
  run_ops ops_uint64;
  run_ops ops_uint128;
  run_ops ops_int8;
  run_ops ops_int16;
  run_ops ops_int32;
  run_ops ops_int64;
  run_ops ops_int128;
  run_casts ();
  FStar.IO.print_string ("machine : exécutés=" ^ string_of_int !executed ^ " ignorés (précondition)=" ^ string_of_int !skipped ^ "\n")
