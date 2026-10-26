module Program

open Ui
open Extracted

/// Seule colle entre l'arbre de vue extrait de F* et l'interpréteur générique.
let rec toNode (v: app_view_tree) : Node =
  match v with
  | App_VColumn xs -> Column (List.map toNode xs)
  | App_VRow xs -> Row (List.map toNode xs)
  | App_VHeading s -> Heading s
  | App_VText s -> Text s
  | App_VButton (l, m) -> Button (l, box m)
  | App_VInput (t, v, h) -> Input (box t, v, h)
  | App_VCheck (l, c, m) -> Check (l, c, box m)

let api : CoreApi =
  { Init = box app_init
    Update = fun m g -> box (app_update (unbox m) (unbox g))
    View = fun m -> toNode (app_view (unbox m))
    MsgOfInput = fun t s -> box (app_msg_of_input (unbox t) s) }

/// Résumé du modèle pour le journal de test (MVU_TRACE) ; concaténation typée, sans réflexion.
let describe (m: app_model) =
  let tab = match m.tab with App_TCounter -> "counter" | App_TItems -> "items" | App_TForm -> "form"
  let items = m.items |> List.map (fun i -> i.text + (if i.``checked`` then "[x]" else "[ ]")) |> String.concat ","
  let status =
    match m.status with
    | App_Editing -> "editing"
    | App_Rejected es -> "rejected:" + String.concat "|" es
    | App_Accepted (n, a, h) -> "accepted:" + n + "," + string a + "," + string h
  "tab=" + tab + " counter=" + string m.counter + " items=" + items + " draft=" + m.draft
  + " name=" + m.name + " age=" + m.age + " status=" + status

[<EntryPoint>]
let main argv =
  Startup.run argv (fun lt ->
    let w = Startup.newWindow ()
    let r = Runner(api, w)
    match System.Environment.GetEnvironmentVariable "MVU_TRACE" with
    | null | "" -> ()
    | path -> r.OnRender <- fun m -> System.IO.File.AppendAllText(path, describe (unbox m) + "\n")
    lt.MainWindow <- w
    w.Opened.Add(fun _ -> r.Render()))
