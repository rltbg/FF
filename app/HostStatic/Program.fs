module Program

open Avalonia
open Avalonia.Controls
open Avalonia.X11
open Ui
open Extracted

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

[<EntryPoint>]
let main argv =
  UiApp.OnReady <- fun lt ->
    let w = Window(Title = "F* MVU", Width = 520.0, Height = 560.0)
    let r = Runner(api, w)
    lt.MainWindow <- w
    w.Opened.Add(fun _ -> r.Render())
  AppBuilder.Configure<UiApp>()
    .UseX11()
    .UseSkia()
    .UseHarfBuzz()
    .With(X11PlatformOptions(RenderingMode = [| X11RenderingMode.Software |]))
    .StartWithClassicDesktopLifetime(argv)
