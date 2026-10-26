module Program

open System
open Extracted

let mutable checks = 0
let mutable fails = 0
let check (name: string) (ok: bool) =
  checks <- checks + 1
  if not ok then
    fails <- fails + 1
    if fails <= 20 then Console.WriteLine("FAIL: " + name)

let chars (s: string) : char list = List.ofSeq s
let bytes (s: string) : uint8 list = s |> Seq.map (fun c -> uint8 c) |> List.ofSeq

// implémentation de référence indépendante (boucle impérative)
let refFnv (bs: uint8 list) : uint32 =
  let mutable h = 2166136261u
  for b in bs do
    h <- (h ^^^ uint32 b) * 16777619u
  h

let rng = Random(12345)
let randBytes n = [ for _ in 1 .. n -> uint8 (rng.Next 256) ]
let randStr n (alphabet: string) = String([| for _ in 1 .. n -> alphabet.[rng.Next alphabet.Length] |])

let testFnv () =
  // vecteurs publics FNV-1a 32 bits
  check "fnv ''" (core_fnv [] = 0x811C9DC5u)
  check "fnv 'a'" (core_fnv (bytes "a") = 0xE40C292Cu)
  check "fnv 'foobar'" (core_fnv (bytes "foobar") = 0xBF9CF968u)
  check "fnv magic" (core_fnv_magic = (2166136261u ^^^ 0xA5u) * 16777619u)
  check "magic literal" (core_magic = 165uy)
  // lemme fnv_append : fnv_from h (a@b) = fnv_from (fnv_from h a) b
  for _ in 1 .. 20000 do
    let a = randBytes (rng.Next 40)
    let b = randBytes (rng.Next 40)
    let h = uint32 (rng.NextInt64())
    check "fnv_append" (core_fnv_from h (a @ b) = core_fnv_from (core_fnv_from h a) b)
    check "fnv = ref" (core_fnv a = refFnv a)
  // octets extrêmes
  check "fnv 0x00" (core_fnv [ 0uy ] = refFnv [ 0uy ])
  check "fnv 0xff" (core_fnv [ 255uy ] = refFnv [ 255uy ])

let testParse () =
  let nat s = core_parse_nat (chars s)
  let age s = core_parse_age (chars s)
  check "nat '' = None" (nat "" = None)          // lemma_empty_rejected
  check "nat '0'" (nat "0" = Some 0u)
  check "nat '007'" (nat "007" = Some 7u)
  check "nat '1000'" (nat "1000" = Some 1000u)
  check "nat '1001' = None" (nat "1001" = None)
  check "nat '99999999999999999999' = None" (nat "99999999999999999999" = None)
  check "nat zeros longs" (nat (String('0', 500) + "5") = Some 5u)
  check "nat ' 5'" (nat " 5" = None)
  check "nat '+5'" (nat "+5" = None)
  check "nat '-5'" (nat "-5" = None)
  check "nat '5 '" (nat "5 " = None)
  check "nat arabic-indic digit" (nat "٣" = None)
  check "nat fullwidth digit" (nat "５" = None)
  check "nat '/' (47)" (nat "/" = None)
  check "nat ':' (58)" (nat ":" = None)
  check "age '150'" (age "150" = Some 150u)
  check "age '151' = None" (age "151" = None)
  check "age '0'" (age "0" = Some 0u)
  check "age 'abc'" (age "abc" = None)
  // lemma_parse_bounded : tout Some n a n <= 150 ; différentiel contre Int64.Parse
  for _ in 1 .. 200000 do
    let s = randStr (rng.Next 6) "0123456789 +-x"
    match age s with
    | Some n -> check ("age bounded " + s) (n <= 150u)
    | None -> ()
    let expectNat =
      if s.Length > 0 && s |> Seq.forall (fun c -> c >= '0' && c <= '9') then
        let v = Int64.Parse s
        if v <= 1000L then Some (uint32 v) else None
      else None
    check ("nat diff " + s) (nat s = expectNat)

let testName () =
  let ok s = core_name_ok (chars s)
  check "name ''" (not (ok ""))
  check "name 1" (ok "a")
  check "name 20" (ok (String('a', 20)))
  check "name 21" (not (ok (String('a', 21))))
  check "name ctrl" (not (ok "a\tb"))
  check "name 0x1f" (not (ok "a\u001fb"))
  check "name space (32)" (ok " ")
  check "name accents" (ok "Éloïse")

// ---------- propriétés de update/view, avec invariant indépendant ----------
let indepInv (m: app_model) =
  let ids = m.items |> List.map (fun i -> i.id)
  let rec strictlyDecreasing = function
    | a :: (b :: _ as t) -> a > b && strictlyDecreasing t
    | _ -> true
  m.counter >= -1000I && m.counter <= 1000I
  && strictlyDecreasing ids
  && ids |> List.forall (fun i -> i < m.next_id)

let rec leaves (v: app_view_tree) : int =
  match v with
  | App_VColumn xs | App_VRow xs -> xs |> List.sumBy leaves
  | _ -> 1

let randMsg (m: app_model) : app_msg =
  match rng.Next 12 with
  | 0 | 1 | 2 -> App_Inc
  | 3 -> App_Dec
  | 4 -> App_Reset
  | 5 -> App_Goto (match rng.Next 3 with 0 -> App_TCounter | 1 -> App_TItems | _ -> App_TForm)
  | 6 | 7 -> App_Typed (App_InNew, randStr (rng.Next 25) "abc é")
  | 8 -> App_AddItem
  | 9 -> (match m.items with [] -> App_ClearChecked | xs -> App_Remove (List.item (rng.Next xs.Length) xs).id)
  | 10 -> (match m.items with [] -> App_ClearChecked | xs -> App_Toggle (List.item (rng.Next xs.Length) xs).id)
  | _ -> (match rng.Next 4 with
          | 0 -> App_Typed (App_InName, randStr (rng.Next 25) "ab\t ")
          | 1 -> App_Typed (App_InAge, randStr (rng.Next 5) "0123456789x")
          | 2 -> App_ClearChecked
          | _ -> App_Submit)

let testUpdate () =
  check "init inv" (app_inv app_init && indepInv app_init)
  // lemma_inc_dec
  let m0 = { app_init with counter = 5I }
  check "inc/dec" ((app_update (app_update m0 App_Inc) App_Dec).counter = 5I)
  check "inc sature" ((app_update { m0 with counter = 1000I } App_Inc).counter = 1000I)
  check "dec sature" ((app_update { m0 with counter = -1000I } App_Dec).counter = -1000I)
  // marches aléatoires : invariant, remove_gone, add_grows, accepted_valid
  for run in 1 .. 300 do
    let mutable m = app_init
    for step in 1 .. 400 do
      let g = randMsg m
      let before = m
      m <- app_update m g
      check "inv" (app_inv m)
      check "indep inv" (indepInv m)
      match g with
      | App_AddItem ->
        let added = m.items.Length = before.items.Length + 1
        let refused = m.items.Length = before.items.Length
        check "add: +1 ou refus" (added || refused)
        let nameOk = core_name_ok (chars before.draft)
        check "add <=> name_ok" (added = nameOk)           // lemma_add_grows
      | App_Remove k -> check "remove gone" (not (m.items |> List.exists (fun i -> i.id = k)))   // lemma_remove_gone
      | App_ClearChecked -> check "clear" (m.items |> List.forall (fun i -> not i.``checked``))
      | App_Submit ->
        match m.status with
        | App_Accepted (n, a, h) ->
          check "accepted age <=150" (a <= 150u)         // lemma_accepted_valid
          check "accepted hash" (h = refFnv (bytes n))
          check "accepted name ok" (core_name_ok (chars n))
        | App_Rejected es -> check "rejected: raisons" (not es.IsEmpty)
        | App_Editing -> check "submit ne laisse pas Editing" false
      | _ -> ()
      // view totale
      check "view non vide" (leaves (app_view m) > 0)

let run () =
  testFnv (); testParse (); testName (); testUpdate ()
  Console.WriteLine("checks=" + string checks + " fails=" + string fails)
  if fails = 0 then 0 else 1

let bench () =
  let time (name: string) (n: int) (f: unit -> unit) =
    for _ in 1 .. n / 10 do f ()
    let sw = Diagnostics.Stopwatch.StartNew()
    for _ in 1 .. n do f ()
    sw.Stop()
    Console.WriteLine(name + ": " + (sw.Elapsed.TotalMilliseconds * 1000.0 / float n).ToString("F2") + " us/op")
  let b64 = randBytes 64
  let mutable sink = 0u
  time "fnv 64 octets" 200000 (fun () -> sink <- sink + core_fnv b64)
  let mutable m = app_init
  for i in 1 .. 1000 do
    m <- app_update m (App_Typed (App_InNew, "item " + string i))
    m <- app_update m App_AddItem
  Console.WriteLine("items=" + string m.items.Length)
  time "update Inc" 200000 (fun () -> m <- app_update m App_Inc; m <- app_update m App_Dec)
  time "update Toggle (1000 items)" 5000 (fun () -> m <- app_update m (App_Toggle 500u))
  time "view (1000 items)" 2000 (fun () -> sink <- sink + uint32 (leaves (app_view { m with tab = App_TItems })))
  Console.WriteLine("sink=" + string sink)

[<EntryPoint>]
let main argv = if argv.Length > 0 && argv.[0] = "bench" then (bench (); 0) else run ()
