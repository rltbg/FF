module Program

// Tests exécutables des propriétés prouvées en F* (et de ce que les preuves ne couvrent pas,
// comme les constantes FNV). Pas de printf/sprintf : le même binaire tourne en NativeAOT.
open System
open System.Text
open Extracted

let mutable checks = 0
let mutable fails = 0
let check (name: string) (ok: bool) =
  checks <- checks + 1
  if not ok then
    fails <- fails + 1
    if fails <= 20 then Console.WriteLine("FAIL: " + name)

let chars (s: string) : char list = List.ofSeq s
let ascii (s: string) : uint8 list = Encoding.ASCII.GetBytes s |> List.ofArray

/// Implémentation de référence indépendante (draft-eastlake-fnv-21, §2).
let refFnv (bs: seq<byte>) : uint32 =
  let mutable h = 0x811C9DC5u
  for b in bs do
    h <- (h ^^^ uint32 b) * 0x01000193u
  h
let refFnvUtf8 (s: string) = refFnv (Encoding.UTF8.GetBytes s)

let rng = Random(12345)
let randBytes n = Array.init n (fun _ -> byte (rng.Next 256))
let randStr n (alphabet: string) = String(Array.init n (fun _ -> alphabet.[rng.Next alphabet.Length]))

let testFnv () =
  // draft-eastlake-fnv-21, annexe C, tables 3 et 4 (FNV32, FNV-1a)
  check "fnv ''" (core_fnv [] = 0x811c9dc5u)
  check "fnv 'a'" (core_fnv (ascii "a") = 0xe40c292cu)
  check "fnv 'foobar'" (core_fnv (ascii "foobar") = 0xbf9cf968u)
  check "fnv '\\0'" (core_fnv [ 0uy ] = 0x050c5d1fu)
  check "fnv 'a\\0'" (core_fnv (ascii "a" @ [ 0uy ]) = 0x2b24d044u)
  check "fnv 'foobar\\0'" (core_fnv (ascii "foobar" @ [ 0uy ]) = 0x0c1c9eb8u)
  check "fnv_bytes 'foobar'" (core_fnv_bytes (Encoding.ASCII.GetBytes "foobar") = 0xbf9cf968u)
  check "fnv_bytes vide" (core_fnv_bytes [||] = 0x811c9dc5u)
  check "fnv_utf8 'foobar'" (core_fnv_utf8 "foobar" = 0xbf9cf968u)
  check "magic u8" (core_magic = 0xA5uy)
  check "fnv magic" (core_fnv_magic = (0x811C9DC5u ^^^ 0xA5u) * 0x01000193u)
  // UTF-8 : plus de collision entre U+0100 et U+0000 (défaut de la 1re passe : octet bas UTF-16)
  check "utf8 Ā <> \\0" (core_fnv_utf8 "Ā" <> core_fnv_utf8 "\u0000")
  check "utf8 é" (core_fnv_utf8 "é" = refFnv [| 0xC3uy; 0xA9uy |])
  check "utf8 emoji" (core_fnv_utf8 "🙂" = refFnv [| 0xF0uy; 0x9Fuy; 0x99uy; 0x82uy |])
  for _ in 1 .. 20000 do
    let a = randBytes (rng.Next 40)
    let b = randBytes (rng.Next 40)
    let h = uint32 (rng.NextInt64())
    // lemme fnv_append
    check "fnv_append" (core_fnv_from h (List.ofArray (Array.append a b)) = core_fnv_from (core_fnv_from h (List.ofArray a)) (List.ofArray b))
    // lemme lemma_fnv_bytes : implémentation tableau = spécification liste
    check "fnv_bytes = fnv" (core_fnv_bytes a = core_fnv (List.ofArray a))
    check "fnv = ref" (core_fnv (List.ofArray a) = refFnv a)
    let s = randStr (rng.Next 12) "aZ09 éàß€🙂Ā"
    check "fnv_utf8 = ref" (core_fnv_utf8 s = refFnvUtf8 s)

let testParse () =
  let nat s = core_parse_nat (chars s)
  let age s = core_parse_age (chars s)
  check "nat '' = None" (nat "" = None)          // lemma_empty_rejected
  check "nat '0'" (nat "0" = Some 0u)
  check "nat '007'" (nat "007" = Some 7u)
  check "nat '1000'" (nat "1000" = Some 1000u)
  check "nat '1001' = None" (nat "1001" = None)
  check "nat 20 chiffres = None" (nat "99999999999999999999" = None)
  check "nat zéros longs" (nat (String('0', 500) + "5") = Some 5u)
  check "nat ' 5'" (nat " 5" = None)
  check "nat '+5'" (nat "+5" = None)
  check "nat '-5'" (nat "-5" = None)
  check "nat '5 '" (nat "5 " = None)
  check "nat chiffre arabe-indien" (nat "٣" = None)
  check "nat chiffre pleine chasse" (nat "５" = None)
  check "nat '/' (0x2F)" (nat "/" = None)
  check "nat ':' (0x3A)" (nat ":" = None)
  check "age '150'" (age "150" = Some 150u)
  check "age '151' = None" (age "151" = None)
  check "age '0'" (age "0" = Some 0u)
  check "age 'abc'" (age "abc" = None)
  // lemma_parse_nat (correction fonctionnelle) et lemma_parse_bounded, en différentiel
  for _ in 1 .. 200000 do
    let s = randStr (rng.Next 6) "0123456789 +-x٣"
    let expectNat =
      if s.Length > 0 && s |> Seq.forall (fun c -> c >= '0' && c <= '9') then
        let v = Int64.Parse s
        if v <= 1000L then Some (uint32 v) else None
      else None
    check ("nat diff " + s) (nat s = expectNat)
    let expectAge = match expectNat with Some n when n <= 150u -> Some n | _ -> None
    check ("age diff " + s) (age s = expectAge)

let testName () =
  let ok s = core_name_ok (chars s)
  check "nom vide" (not (ok ""))
  check "nom 1" (ok "a")
  check "nom 20" (ok (String('a', 20)))
  check "nom 21" (not (ok (String('a', 21))))
  check "nom tab" (not (ok "a\tb"))
  check "nom 0x1F" (not (ok "a\u001fb"))
  check "nom espace 0x20" (ok " ")
  check "nom ~ 0x7E" (ok "~")
  check "nom DEL 0x7F" (not (ok "a\u007fb"))
  check "nom C1 0x80" (not (ok "a\u0080b"))
  check "nom C1 0x9F" (not (ok "a\u009fb"))
  check "nom NBSP 0xA0" (ok "a b")
  check "nom accents" (ok "Éloïse")
  check "nom emoji = 2 unités UTF-16" (ok (String.replicate 10 "🙂") && not (ok (String.replicate 11 "🙂")))
  for c in 0 .. 0xFFFF do
    let expected = c >= 32 && not (c >= 127 && c <= 159)
    check ("printable " + string c) (core_printable (char c) = expected)

// ---------- update / view, avec un invariant recalculé indépendamment ----------
let indepInv (m: app_model) =
  let ids = m.items |> List.map (fun i -> i.id)
  let rec strictlyDecreasing = function
    | a :: (b :: _ as t) -> a > b && strictlyDecreasing t
    | _ -> true
  m.counter >= -1000 && m.counter <= 1000
  && strictlyDecreasing ids
  && ids |> List.forall (fun i -> i < m.next_id)
  && m.next_id < UInt32.MaxValue

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
  | 6 | 7 -> App_Typed (App_InNew, randStr (rng.Next 25) "abc é\u007f")
  | 8 -> App_AddItem
  | 9 -> (match m.items with [] -> App_ClearChecked | xs -> App_Remove (List.item (rng.Next xs.Length) xs).id)
  | 10 -> (match m.items with [] -> App_ClearChecked | xs -> App_Toggle (List.item (rng.Next xs.Length) xs).id)
  | _ -> (match rng.Next 4 with
          | 0 -> App_Typed (App_InName, randStr (rng.Next 25) "ab\t é🙂")
          | 1 -> App_Typed (App_InAge, randStr (rng.Next 5) "0123456789x")
          | 2 -> App_ClearChecked
          | _ -> App_Submit)

let testUpdate () =
  check "init inv" (app_inv app_init && indepInv app_init)
  let m0 = { app_init with counter = 5 }
  check "inc/dec" ((app_update (app_update m0 App_Inc) App_Dec).counter = 5)       // lemma_inc_dec
  check "inc sature" ((app_update { m0 with counter = 1000 } App_Inc).counter = 1000)
  check "dec sature" ((app_update { m0 with counter = -1000 } App_Dec).counter = -1000)
  check "reset" ((app_update m0 App_Reset).counter = 0)
  // garde de débordement des identifiants
  let full = { app_init with next_id = 0xFFFFFFFEu; draft = "x" }
  check "add refusé à next_id max" ((app_update full App_AddItem).items.IsEmpty)
  let nearFull = { app_init with next_id = 0xFFFFFFFDu; draft = "x" }
  let added = app_update nearFull App_AddItem
  check "add accepté juste avant max" (added.items.Length = 1 && added.next_id = 0xFFFFFFFEu && app_inv added)
  for _ in 1 .. 300 do
    let mutable m = app_init
    for _ in 1 .. 400 do
      let g = randMsg m
      let before = m
      m <- app_update m g
      check "inv" (app_inv m)
      check "inv indépendant" (indepInv m)
      match g with
      | App_AddItem ->
        let added = m.items.Length = before.items.Length + 1
        check "add : +1 ou refus" (added || m.items.Length = before.items.Length)
        check "add <=> name_ok" (added = core_name_ok (chars before.draft))   // lemma_add_grows
      | App_Remove k -> check "remove" (not (m.items |> List.exists (fun i -> i.id = k)))   // lemma_remove_gone
      | App_ClearChecked -> check "clear" (m.items |> List.forall (fun i -> not i.``checked``))
      | App_Submit ->
        // lemma_accepted_valid
        let nameOk = core_name_ok (chars before.name)
        let ageP = core_parse_age (chars before.age)
        match m.status with
        | App_Accepted (n, a, h) ->
          check "accepted : nom" (n = before.name && nameOk)
          check "accepted : âge" (ageP = Some a && a <= 150u)
          check "accepted : empreinte UTF-8" (h = refFnvUtf8 n)
        | App_Rejected es -> check "rejected" (not es.IsEmpty && (not nameOk || ageP.IsNone))
        | App_Editing -> check "submit ne laisse pas Editing" false
      | _ -> ()
      check "view non vide" (leaves (app_view m) > 0)

let run () =
  testFnv (); testParse (); testName (); testUpdate ()
  Console.WriteLine("checks=" + string checks + " fails=" + string fails)
  if fails = 0 then 0 else 1

let bench () =
  let time (name: string) (n: int) (f: unit -> unit) =
    for _ in 1 .. max 1 (n / 5) do f ()                 // échauffement (tiering JIT)
    let sw = Diagnostics.Stopwatch.StartNew()
    for _ in 1 .. n do f ()
    sw.Stop()
    Console.WriteLine(name + ": " + (sw.Elapsed.TotalMilliseconds * 1000.0 / float n).ToString("F3") + " us/op")
  let mutable sink = 0u
  let b64 = randBytes 64
  let l64 = List.ofArray b64
  time "fnv_bytes 64 octets (byte[])" 2000000 (fun () -> sink <- sink + core_fnv_bytes b64)
  time "fnv 64 octets (liste)" 2000000 (fun () -> sink <- sink + core_fnv l64)
  time "fnv_utf8 nom de 12 car." 1000000 (fun () -> sink <- sink + core_fnv_utf8 "Ada Lovelace")
  let mutable m = app_init
  for i in 1 .. 1000 do
    m <- app_update m (App_Typed (App_InNew, "item " + string i))
    m <- app_update m App_AddItem
  Console.WriteLine("items=" + string m.items.Length)
  time "update Inc+Dec" 1000000 (fun () -> m <- app_update m App_Inc; m <- app_update m App_Dec)
  time "update Toggle (1000 items)" 20000 (fun () -> m <- app_update m (App_Toggle 500u))
  let mi = { m with tab = App_TItems }
  time "view (1000 items)" 5000 (fun () -> sink <- sink + uint32 (leaves (app_view mi)))
  Console.WriteLine("sink=" + string sink)

[<EntryPoint>]
let main argv = if argv.Length > 0 && argv.[0] = "bench" then (bench (); 0) else run ()
