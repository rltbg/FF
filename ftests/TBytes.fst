module TBytes
(* FStar.Bytes (byte[] en F#) : toutes les fonctions réalisées par Custard, contre leur contrat (ulib/FStar.Bytes.fsti)
   et des valeurs écrites à la main. Les octets sont construits par [abyte]/[append] (aucune conversion u8 -> int).
   Les fonctions à précondition sont appelées derrière des gardes exécutées (wrappers *_ : option). *)
open FStar.All
open TUtil
module B   = FStar.Bytes
module U8  = FStar.UInt8
module U16 = FStar.UInt16
module U32 = FStar.UInt32
module S   = FStar.String
open FStar.List.Tot

(* ---- wrappers gardés ---- *)
let get_ (b:B.bytes) (p:U32.t) : option U8.t = if U32.lt p (B.len b) then Some (B.get b p) else None
let append_ (a b:B.bytes) : option B.bytes =
  if U32.lt (B.len a) 0x7FFFFFFFul && U32.lt (B.len b) 0x7FFFFFFFul then Some (B.append a b) else None
let slice_ (b:B.bytes) (s e:U32.t) : option B.bytes =
  if U32.lte s e && U32.lte e (B.len b) then Some (B.slice b s e) else None
let sub_ (b:B.bytes) (s l:U32.t) : option B.bytes =
  if U32.lte s (B.len b) && U32.lte l (U32.sub (B.len b) s) then Some (B.sub b s l) else None
let split_ (b:B.bytes) (k:U32.t) : option (B.bytes & B.bytes) =
  if U32.lte k (B.len b) then Some (B.split b k) else None
let xor_ (n:U32.t) (a b:B.bytes) : option B.bytes =
  if U32.lte n (B.len a) && U32.lte n (B.len b) then Some (B.xor n a b) else None
let bytes_of_int_ (k n:int) : option B.bytes =
  assert_norm (pow2 32 == 4294967296);
  if k >= 0 && n >= 0 && k < 4294967296 && B.repr_bytes n <= k then Some (B.bytes_of_int k n) else None
let int32_ (b:B.bytes) : option U32.t = if U32.lte (B.len b) 4ul then Some (B.int32_of_bytes b) else None
let int16_ (b:B.bytes) : option U16.t = if U32.lte (B.len b) 2ul then Some (B.int16_of_bytes b) else None
let int8_  (b:B.bytes) : option U8.t  = if U32.eq (B.len b) 1ul then Some (B.int8_of_bytes b) else None
let utf8_ (s:string) : option B.bytes = if S.length s <= 4000000 then (Core.lemma_len_maxlen s; Some (B.utf8_encode s)) else None

(* bytes <- liste d'entiers 0..255 *)
let rec of_list (l:list int) : ML B.bytes =
  match l with
  | [] -> B.empty_bytes
  | x :: t -> let r = of_list t in (match append_ (B.abyte (u8_of x)) r with Some y -> y | None -> r)

let byte_at (b:B.bytes) (i:int) : option U8.t = if i >= 0 then get_ b (u32_of i) else None

(* b contient exactement les octets de l *)
let is_list (b:B.bytes) (l:list int) : ML bool =
  U32.eq (B.len b) (u32_of (length l)) &&
  (let rec go (i:nat) (m:list int) : ML bool =
     match m with
     | [] -> true
     | x :: t -> (match byte_at b i with Some y -> U8.eq y (u8_of x) && go (i + 1) t | None -> false) in
   go 0 l)

let opt_is (r:option B.bytes) (l:list int) : ML bool = match r with Some b -> is_list b l | None -> false

let rec xor_lists (a b:list int) : Tot (list int) (decreases a) =
  match a, b with x :: s, y :: t -> xor_bits x y 8 :: xor_lists s t | _ -> []

let rb (n:nat) : ML (list int) = rand_list n (fun () -> rand_below 256)

let test_basic () : ML unit =
  let e = blur B.empty_bytes in
  check "empty_bytes/len" (U32.eq (B.len e) 0ul);
  let b = of_list (blur [10; 20; 30; 255; 0]) in
  check "of_list/len/get" (is_list b [10; 20; 30; 255; 0]);
  check "get" (get_ b 3ul = Some 255uy && get_ b 4ul = Some 0uy && get_ b 5ul = None);
  check "create" (is_list (B.create (blur 4ul) 7uy) [7; 7; 7; 7]);
  check "create 0" (U32.eq (B.len (B.create (blur 0ul) 7uy)) 0ul);
  check "abyte/twobytes" (is_list (B.abyte (blur 9uy)) [9] && is_list (B.twobytes (blur 1uy, 2uy)) [1; 2]);
  check "append" (opt_is (append_ b (of_list [1; 2])) [10; 20; 30; 255; 0; 1; 2] && opt_is (append_ e b) [10; 20; 30; 255; 0]);
  check "slice" (opt_is (slice_ b 1ul 4ul) [20; 30; 255] && opt_is (slice_ b 2ul 2ul) [] && slice_ b 3ul 2ul = None && slice_ b 0ul 6ul = None);
  check "sub" (opt_is (sub_ b 1ul 3ul) [20; 30; 255] && opt_is (sub_ b 5ul 0ul) [] && sub_ b 3ul 3ul = None);
  check "split" (match split_ b 2ul with Some (x, y) -> is_list x [10; 20] && is_list y [30; 255; 0] | None -> false);
  check "split 0 / len" (match split_ b 0ul with Some (x, y) -> is_list x [] && is_list y [10; 20; 30; 255; 0] | None -> false);
  check "split > len refusé" (split_ b 6ul = None);
  check "init" (is_list (B.init 3ul (fun (i:U32.t) -> 5uy)) [5; 5; 5]);
  check "init dépend de i" (let c = B.init 4ul (fun (i:U32.t) -> if U32.lt i 2ul then 1uy else 2uy) in is_list c [1; 1; 2; 2]);
  check "repr_bytes" (B.repr_bytes (blur 0) = 1 && B.repr_bytes (blur 255) = 1 && B.repr_bytes (blur 256) = 2
                      && B.repr_bytes (blur 65535) = 2 && B.repr_bytes (blur 65536) = 3 && B.repr_bytes (blur 16777216) = 4)

(* entiers <-> octets (grand-boutiste) *)
let test_ints () : ML unit =
  check "int_of_bytes" (B.int_of_bytes (of_list [1; 2]) = 258 && B.int_of_bytes (of_list [255; 255; 255; 255]) = 4294967295
                        && B.int_of_bytes (of_list [0]) = 0 && B.int_of_bytes (blur B.empty_bytes) = 0);
  check "bytes_of_int k=4" (opt_is (bytes_of_int_ 4 (blur 258)) [0; 0; 1; 2]);
  check "bytes_of_int k=2" (opt_is (bytes_of_int_ 2 (blur 258)) [1; 2]);
  check "bytes_of_int trop petit refusé" (bytes_of_int_ 1 (blur 258) = None);
  check "int32_of_bytes" (int32_ (of_list [0; 0; 1; 2]) = Some 258ul && int32_ (of_list [7]) = Some 7ul && int32_ (of_list [1; 2; 3; 4; 5]) = None);
  check "int16_of_bytes" (int16_ (of_list [1; 2]) = Some 258us && int16_ (of_list [3]) = Some 3us);
  check "int8_of_bytes" (int8_ (of_list [200]) = Some 200uy && int8_ (of_list [1; 2]) = None);
  check "bytes_of_int32" (is_list (B.bytes_of_int32 (blur 0x01020304ul)) [1; 2; 3; 4]);
  check "bytes_of_int32 max" (is_list (B.bytes_of_int32 (blur 0xFFFFFFFFul)) [255; 255; 255; 255]);
  check "bytes_of_int16" (is_list (B.bytes_of_int16 (blur 0x0A0Bus)) [10; 11]);
  check "bytes_of_int8" (is_list (B.bytes_of_int8 (blur 0xFEuy)) [254]);
  let rec rt (k:nat) : ML unit =
    if k = 0 then () else begin
      let n = rand_below 4294967296 in
      let x = B.bytes_of_int32 (u32_of n) in
      check "int32_of_bytes (bytes_of_int32 n) = n" (int32_ x = Some (u32_of n));
      check "int_of_bytes (bytes_of_int32 n) = n" (B.int_of_bytes x = n);
      check "bytes_of_int 4 n = bytes_of_int32 n" (match bytes_of_int_ 4 n with Some y -> y = x | None -> false);
      let m = rand_below 65536 in
      let y = B.bytes_of_int16 (U16.uint_to_t m) in
      check "int16 aller-retour" (int16_ y = Some (U16.uint_to_t m));
      rt (k - 1)
    end in
  rt 2000

let test_xor () : ML unit =
  let a = of_list (blur [1; 2; 255; 0]) in
  let b = of_list [3; 2; 255; 1] in
  check "xor" (opt_is (xor_ 4ul a b) [2; 0; 0; 1] && opt_is (xor_ 2ul a b) [2; 0] && xor_ 5ul a b = None);
  let rec rx (k:nat) : ML unit =
    if k = 0 then () else begin
      let n = rand_below 20 in
      let l1 = rb n in let l2 = rb n in
      let x = of_list l1 in let y = of_list l2 in
      check "xor = ref" (opt_is (xor_ (u32_of n) x y) (xor_lists l1 l2));
      check "xor involutif" (match xor_ (u32_of n) x y with
                             | Some z -> opt_is (xor_ (u32_of n) z y) l1
                             | None -> false);
      rx (k - 1)
    end in
  rx 500

let hex_is (b:B.bytes) (e:string) : bool = B.hex_of_bytes b = e

let test_strings () : ML unit =
  check "utf8_encode" (match utf8_ (blur "héllo €") with Some b -> is_list b [104; 195; 169; 108; 108; 111; 32; 226; 130; 172] | None -> false);
  check "bytes_of_string" (is_list (B.bytes_of_string (blur "é")) [195; 169]);
  check "iutf8_opt" (let m = of_list (blur [104; 195; 169]) in match B.iutf8_opt m with Some t -> t = "hé" | None -> false);
  check "iutf8_opt invalide" (let m = of_list (blur [255; 254]) in match B.iutf8_opt m with None -> true | Some _ -> false);
  check "iutf8_opt vide" (let m = blur B.empty_bytes in match B.iutf8_opt m with Some t -> t = "" | None -> false);
  let rec rt (k:nat) : ML unit =
    if k = 0 then () else begin
      let codes = blur (rand_list (rand_below 10) (fun () ->
                    match rand_below 3 with 0 -> rand_below 128 | 1 -> 128 + rand_below 1900 | _ -> 2048 + rand_below 40000)) in
      let t = string_of_codes codes in
      check "utf8_encode = ref" (match utf8_ t with Some b -> is_list b (ref_utf8 codes) | None -> false);
      check "iutf8_opt (utf8_encode t) = Some t"
        (match utf8_ t with Some b -> (match B.iutf8_opt b with Some u -> u = t | None -> false) | None -> false);
      rt (k - 1)
    end in
  rt 1000;
  (* hexadécimal : valeurs de la réalisation Custard (le contrat F* ne les précise pas) + aller-retours *)
  check "hex_of_bytes" (hex_is (of_list (blur [0; 15; 16; 171; 255])) "000f10abff");
  check "print_bytes" (B.print_bytes (of_list (blur [0; 171; 255])) = "00ABFF");
  check "bytes_of_hex" (opt_is (Some (B.bytes_of_hex (blur "00ff10Ab"))) [0; 255; 16; 171]);
  check "hex_of_string" (B.hex_of_string (blur "AZ") = "415a");
  check "string_of_hex" (B.string_of_hex (blur "415a") = "AZ");
  let rec rh (k:nat) : ML unit =
    if k = 0 then () else begin
      let l = rb (rand_below 30) in
      let x = of_list l in
      check "bytes_of_hex (hex_of_bytes b)" (is_list (B.bytes_of_hex (B.hex_of_bytes x)) l);
      check "hex_of_bytes : longueur 2n" (S.length (B.hex_of_bytes x) = 2 * length l);
      rh (k - 1)
    end in
  rh 500

let main () : ML unit = test_basic (); test_ints (); test_xor (); test_strings ()
