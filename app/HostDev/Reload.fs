module Reload

open System
open System.IO
open System.Reflection
open System.Runtime.Loader
open Microsoft.FSharp.Reflection
open Ui

/// Contexte collectible : FSharp.Core et Avalonia ne sont pas chargés ici, la résolution
/// retombe sur le contexte par défaut (partagé avec l'hôte).
type CoreAlc() =
  inherit AssemblyLoadContext("fstar-core", true)

exception TransplantFailed of string

/// Copie structurelle d'une valeur vers le type de même nom d'un autre assembly
/// (enregistrements, unions, listes, tuples, option, primitives). Échoue si la forme a changé.
let rec transplant (src: obj) (target: Type) : obj =
  if isNull src then null // None d'une option
  elif target.IsPrimitive || target = typeof<string> || target = typeof<bigint> || target.IsEnum then
    if src.GetType() <> target then
      raise (TransplantFailed ("type changé: " + src.GetType().Name + " -> " + target.Name))
    src
  elif FSharpType.IsRecord(target, true) then
    let sFields = FSharpType.GetRecordFields(src.GetType(), true)
    let tFields = FSharpType.GetRecordFields(target, true)
    if sFields.Length <> tFields.Length then
      raise (TransplantFailed ("champs changés: " + target.Name))
    let vals =
      tFields |> Array.map (fun tf ->
        match sFields |> Array.tryFind (fun sf -> sf.Name = tf.Name) with
        | Some sf -> transplant (sf.GetValue src) tf.PropertyType
        | None -> raise (TransplantFailed ("champ absent: " + target.Name + "." + tf.Name)))
    FSharpValue.MakeRecord(target, vals, true)
  elif target.IsGenericType && target.GetGenericTypeDefinition() = typedefof<list<_>> then
    let et = target.GetGenericArguments().[0]
    let items = [| for x in (src :?> Collections.IEnumerable) -> transplant x et |]
    let arr = Array.CreateInstance(et, items.Length)
    items |> Array.iteri (fun i x -> arr.SetValue(x, i))
    let ofArray =
      typeof<list<int>>.Assembly.GetType("Microsoft.FSharp.Collections.ListModule")
        .GetMethod("OfArray").MakeGenericMethod(et)
    ofArray.Invoke(null, [| box arr |])
  elif FSharpType.IsTuple target then
    let sv = FSharpValue.GetTupleFields src
    let ts = FSharpType.GetTupleElements target
    if sv.Length <> ts.Length then raise (TransplantFailed "arité de tuple changée")
    FSharpValue.MakeTuple(Array.map2 transplant sv ts, target)
  elif FSharpType.IsUnion(target, true) then
    let sc, sf = FSharpValue.GetUnionFields(src, src.GetType(), true)
    match FSharpType.GetUnionCases(target, true) |> Array.tryFind (fun c -> c.Name = sc.Name) with
    | None -> raise (TransplantFailed ("cas absent: " + target.Name + "." + sc.Name))
    | Some tc ->
      let tfs = tc.GetFields()
      if tfs.Length <> sf.Length then raise (TransplantFailed ("arité changée: " + tc.Name))
      FSharpValue.MakeUnion(tc, Array.map2 (fun v (p: PropertyInfo) -> transplant v p.PropertyType) sf tfs, true)
  else raise (TransplantFailed ("type non géré: " + target.FullName))

let tryTransplant (src: obj) (target: Type) : Result<obj, string> =
  try Ok (transplant src target) with
  | TransplantFailed why -> Error why
  | e -> Error (e.GetType().Name + ": " + e.Message)

/// Conversion réflexive de l'arbre de vue extrait (app_view_tree) en Node.
let rec toNode (v: obj) : Node =
  let c, f = FSharpValue.GetUnionFields(v, v.GetType(), true)
  let kids (o: obj) = [ for x in (o :?> Collections.IEnumerable) -> toNode x ]
  match c.Name with
  | "App_VColumn" -> Column (kids f.[0])
  | "App_VRow" -> Row (kids f.[0])
  | "App_VHeading" -> Heading (f.[0] :?> string)
  | "App_VText" -> Text (f.[0] :?> string)
  | "App_VButton" -> Button (f.[0] :?> string, f.[1])
  | "App_VInput" -> Input (f.[0], f.[1] :?> string, f.[2] :?> string)
  | "App_VCheck" -> Check (f.[0] :?> string, f.[1] :?> bool, f.[2])
  | "App_VBigList" ->
    // f.[2] : option<uint32> (null = None)
    BigList (f.[0] :?> uint32, f.[1] :?> uint32,
             (match f.[2] with null -> -1L | o -> int64 (o.GetType().GetProperty("Value").GetValue(o) :?> uint32)))
  | "App_VBigText" -> BigText (f.[0] :?> uint32, f.[1] :?> uint32)
  | n -> failwith ("noeud de vue inconnu: " + n)

/// Charge Extracted.dll depuis ses octets (pas de verrou sur le fichier) dans un contexte collectible.
/// Renvoie le contexte, l'API du cœur et le type du modèle.
let load (path: string) : CoreAlc * CoreApi * Type =
  let bytes = File.ReadAllBytes path
  let alc = CoreAlc()
  let asm = alc.LoadFromStream(new MemoryStream(bytes))
  let m = asm.GetType("Extracted", true)
  let fn (n: string) =
    match m.GetMethod n with
    | null -> failwith ("fonction absente: " + n)
    | mi -> mi
  let upd, vw, inp = fn "app_update", fn "app_view", fn "app_msg_of_input"
  let msel, mhash = fn "app_msg_of_select", fn "app_msg_of_hash"
  let bitem, bindex = fn "big_item", fn "big_index_of"
  let init = m.GetProperty("app_init").GetValue(null)
  let api =
    { Init = init
      Update = fun mo g -> upd.Invoke(null, [| mo; g |])
      View = fun mo -> toNode (vw.Invoke(null, [| mo |]))
      MsgOfInput = fun t s -> inp.Invoke(null, [| t; s |])
      MsgOfSelect = fun i -> msel.Invoke(null, [| box i |])
      MsgOfHash = fun src -> mhash.Invoke(null, [| box src |])
      BigItem = fun src i -> bitem.Invoke(null, [| box src; box (bigint i) |]) :?> string
      BigIndex = fun src s -> int (bindex.Invoke(null, [| box src; box s |]) :?> bigint) }
  alc, api, upd.GetParameters().[0].ParameterType
