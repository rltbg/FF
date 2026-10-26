namespace HostIOS

open Foundation
open UIKit
open Avalonia
open Avalonia.iOS
open Ui

/// Délégué d'application : démarre Avalonia avec UiApp ; la vue principale vient de Shell.useSingleView.
[<Register("AppDelegate")>]
type AppDelegate() =
  inherit AvaloniaAppDelegate<UiApp>()
  override _.CustomizeAppBuilder(builder: AppBuilder) : AppBuilder =
    Shell.useSingleView ()
    base.CustomizeAppBuilder(builder)

module Entry =
  [<EntryPoint>]
  let main args =
    UIApplication.Main(args, null, typeof<AppDelegate>)
    0
