namespace Ui

open System
open Avalonia
open Avalonia.Controls
open Avalonia.Controls.ApplicationLifetimes
open Avalonia.Themes.Fluent

type UiApp() =
  inherit Application()
  static member val OnReady : IClassicDesktopStyleApplicationLifetime -> unit = ignore with get, set
  override this.Initialize() = this.Styles.Add(FluentTheme())
  // La fenêtre est créée ici : le callback de StartWithClassicDesktopLifetime s'exécute avant
  // l'initialisation de la plateforme (doc : "modify the lifetime before application started").
  override this.OnFrameworkInitializationCompleted() =
    match this.ApplicationLifetime with
    | :? IClassicDesktopStyleApplicationLifetime as lt -> UiApp.OnReady lt
    | _ -> ()
    base.OnFrameworkInitializationCompleted()

/// Boucle MVU : un modèle opaque et un cœur interchangeable (rechargement à chaud).
type Runner(initial: CoreApi, window: Window) as this =
  let mutable api = initial
  let mutable model = initial.Init
  let holder = ScrollViewer()
  let mutable renders = 0
  let interp =
    Interp((fun msg -> this.Dispatch msg),
           (fun tag text -> this.Dispatch(api.MsgOfInput tag text)))

  let render () =
    let root = interp.Render(api.View model)
    if not (obj.ReferenceEquals(holder.Content, root)) then
      root.Margin <- Thickness 16.0
      holder.Content <- root
    renders <- renders + 1
    this.OnRender model

  do window.Content <- holder

  /// Appelé après chaque rendu avec le modèle (journal de test).
  member val OnRender : obj -> unit = ignore with get, set
  member _.Render() = render ()
  member _.Model = model
  member _.CurrentApi = api
  member _.Renders = renders
  member _.Dispatch(msg: obj) =
    model <- api.Update model msg
    render ()
  /// Remplace le cœur et le modèle, oublie les contrôles liés à l'ancien cœur, puis réaffiche.
  member _.Swap(newApi: CoreApi, newModel: obj) =
    api <- newApi
    model <- newModel
    interp.Reset()
    render ()

module Startup =
  /// Configuration documentée Avalonia 12 : UsePlatformDetect (plateforme + Skia + HarfBuzz).
  /// MVU_SOFTWARE_RENDERING=1 force le rendu X11 logiciel (par défaut : modes de la plateforme, avec repli).
  let run (argv: string[]) (onReady: IClassicDesktopStyleApplicationLifetime -> unit) : int =
    UiApp.OnReady <- onReady
    let b = AppBuilder.Configure<UiApp>().UsePlatformDetect()
    let b =
      if Environment.GetEnvironmentVariable "MVU_SOFTWARE_RENDERING" = "1" then
        b.With(X11PlatformOptions(RenderingMode = [| X11RenderingMode.Software |]))
      else b
    b.StartWithClassicDesktopLifetime(argv)

  let newWindow () = Window(Title = "F* MVU", Width = 520.0, Height = 560.0)
