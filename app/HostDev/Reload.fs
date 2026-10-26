module Reload

open System
open System.IO
open System.Reflection
open System.Runtime.Loader
open Microsoft.FSharp.Reflection
open Ui

type CoreAlc() =
  inherit AssemblyLoadContext("core", true)

exception TransplantFailed of string

/// Copie structurelle d'une valeur d'un assembly vers le type de même nom d'un autre assembly.
let rec transplant (src: obj) (target: Type) : obj =
  if isNull src then null
  elif target.IsPrimitive || target = typeof<string> || target = typeof<bigint> || target.IsEnum then src
  elif FSharpType.IsRecord(target, true) then
    let sFields = FSharpType.GetRecordFields(src.GetType(), true)
    let tFields = FSharpType.GetRecordFields(target, true)
    let vals =
      tFields |> Array.map (fun tf ->
        match sFields |> Array.tryFind (fun sf -> sf.Name = tf.Name) with
        | Some sf -> transplant (sf.GetValue src) tf.PropertyType
        | None -> raise (TransplantFailed ("champ absent: " + target.Name + "." + tf.Name)))
    FSharpValue.MakeRecord(target, vals, true)
  elif target.IsGenericType && target.GetGenericTypeDefinition() = typedefof<list<_>> then
    let et = target.GetGenericArguments().[0]
    let items = [ for x in (src :?> System.Collections.IEnumerable) -> transplant x et ]
    let arr = Array.CreateInstance(et, items.Length)
    items |> List.iteri (fun i x -> arr.SetValue(x, i))
    let m = typeof<list<int>>.Assembly.GetType("Microsoft.FSharp.Collections.ListModule").GetMethod("OfArray").MakeGenericMethod(et)
    m.Invoke(null, [| box arr |])
  elif FSharpType.IsTuple target then
    let sv = FSharpValue.GetTupleFields src
    let ts = FSharpType.GetTupleElements target
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

let rec toNode (v: obj) : Node =
  let c, f = FSharpValue.GetUnionFields(v, v.GetType(), true)
  let kids (o: obj) = [ for x in (o :?> System.Collections.IEnumerable) -> toNode x ]
  match c.Name with
  | "App_VColumn" -> Column (kids f.[0])
  | "App_VRow" -> Row (kids f.[0])
  | "App_VHeading" -> Heading (f.[0] :?> string)
  | "App_VText" -> Text (f.[0] :?> string)
  | "App_VButton" -> Button (f.[0] :?> string, f.[1])
  | "App_VInput" -> Input (f.[0], f.[1] :?> string, f.[2] :?> string)
  | "App_VCheck" -> Check (f.[0] :?> string, f.[1] :?> bool, f.[2])
  | n -> raise (TransplantFailed ("noeud de vue inconnu: " + n))

/// Charge Extracted.dll depuis des octets (pas de verrou de fichier) dans un contexte collectible.
let load (path: string) : CoreAlc * Assembly * CoreApi * (obj -> Type) =
  let bytes =
    let rec go n =
      try File.ReadAllBytes path with :? IOException when n > 0 -> Threading.Thread.Sleep 100; go (n - 1)
    go 30
  let alc = CoreAlc()
  let asm = alc.LoadFromStream(new MemoryStream(bytes))
  let m = asm.GetType("Extracted")
  let fn (n: string) = m.GetMethod(n)
  let upd, vw, inp = fn "app_update", fn "app_view", fn "app_msg_of_input"
  let init = m.GetProperty("app_init").GetValue(null)
  let api =
    { Init = init
      Update = fun mo g -> upd.Invoke(null, [| mo; g |])
      View = fun mo -> toNode (vw.Invoke(null, [| mo |]))
      MsgOfInput = fun t s -> inp.Invoke(null, [| t; s |]) }
  alc, asm, api, (fun _ -> upd.GetParameters().[0].ParameterType)
