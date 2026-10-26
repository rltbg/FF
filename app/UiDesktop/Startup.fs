namespace Ui

open System
open Avalonia
open Avalonia.Controls
open Avalonia.Controls.ApplicationLifetimes

module Startup =
  /// Configuration documentée Avalonia 12 : UsePlatformDetect (plateforme + Skia + HarfBuzz).
  /// MVU_SOFTWARE_RENDERING=1 force le rendu X11 logiciel (par défaut : modes de la plateforme, avec repli ; sans effet hors X11).
  let run (argv: string[]) (onReady: IClassicDesktopStyleApplicationLifetime -> unit) : int =
    UiApp.OnReady <- onReady
    let b = AppBuilder.Configure<UiApp>().UsePlatformDetect()
    let b =
      if Environment.GetEnvironmentVariable "MVU_SOFTWARE_RENDERING" = "1" then
        b.With(X11PlatformOptions(RenderingMode = [| X11RenderingMode.Software |]))
      else b
    b.StartWithClassicDesktopLifetime(argv)

  let newWindow () = Window(Title = "F* MVU", Width = 520.0, Height = 560.0)
