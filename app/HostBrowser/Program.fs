module Program

open System.Runtime.Versioning
open Avalonia
open Avalonia.Browser
open Ui

[<assembly: SupportedOSPlatform("browser")>]
do ()

/// Tête NAVIGATEUR : la vue est montée dans l'élément <div id="out"> de wwwroot/index.html.
[<EntryPoint>]
let main _ =
  Shell.useSingleView ()
  AppBuilder.Configure<UiApp>().StartBrowserAppAsync("out") |> ignore
  0
