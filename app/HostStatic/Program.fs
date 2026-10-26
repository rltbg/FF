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
  | App_VBigList (src, rows, sel) -> BigList (src, rows, (match sel with Some i -> int64 i | None -> -1L))
  | App_VBigText (src, lines) -> BigText (src, lines)

let api : CoreApi =
  { Init = box app_init
    Update = fun m g -> box (app_update (unbox m) (unbox g))
    View = fun m -> toNode (app_view (unbox m))
    MsgOfInput = fun t s -> box (app_msg_of_input (unbox t) s)
    MsgOfSelect = fun i -> box (app_msg_of_select i)
    MsgOfHash = fun src -> box (app_msg_of_hash src)
    BigItem = fun src i -> big_item src (bigint i)
    BigIndex = fun src s -> int (big_index_of src s) }

[<EntryPoint>]
let main argv =
  Startup.run argv (fun lt ->
    let w = Startup.newWindow ()
    let r = Runner(api, w)
    match System.Environment.GetEnvironmentVariable "MVU_TRACE" with
    | null | "" -> ()
    | path -> r.OnRender <- fun m -> System.IO.File.AppendAllText(path, app_show_model (unbox m) + " ms=" + r.LastRenderMs.ToString("F1") + "\n")
    // test : MVU_PRELOAD=N ajoute N éléments à la liste avant le premier rendu
    match System.Environment.GetEnvironmentVariable "MVU_PRELOAD" with
    | null | "" -> ()
    | n ->
      r.Preload (List.map box (app_preload_msgs (bigint (int n))))
    lt.MainWindow <- w
    w.Opened.Add(fun _ -> r.Render()))
