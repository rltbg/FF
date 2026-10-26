namespace Ui

open Avalonia
open Avalonia.Controls
open Avalonia.Themes.Fluent

type UiApp() =
  inherit Application()
  static member val OnReady : (Avalonia.Controls.ApplicationLifetimes.IClassicDesktopStyleApplicationLifetime -> unit) = ignore with get, set
  override this.Initialize() = this.Styles.Add(FluentTheme())
  override this.OnFrameworkInitializationCompleted() =
    match this.ApplicationLifetime with
    | :? Avalonia.Controls.ApplicationLifetimes.IClassicDesktopStyleApplicationLifetime as lt -> UiApp.OnReady lt
    | _ -> ()
    base.OnFrameworkInitializationCompleted()

/// Boucle MVU : un modèle opaque, un cœur interchangeable (rechargement à chaud).
type Runner(initial: CoreApi, window: Window) =
  let mutable api = initial
  let mutable model = initial.Init
  let holder = ScrollViewer()
  let mutable interp : Interp = Unchecked.defaultof<Interp>
  let mutable renders = 0

  let render () =
    let tree = api.View model
    let focused = TopLevel.GetTopLevel(holder).FocusManager.GetFocusedElement()
    let root = interp.Build tree
    root.Margin <- Thickness 16.0
    holder.Content <- root
    match focused with
    | :? TextBox as tb -> tb.Focus() |> ignore
    | _ -> ()
    renders <- renders + 1

  do
    interp <-
      Interp((fun msg -> model <- api.Update model msg; render ()),
             (fun tag text -> model <- api.Update model (api.MsgOfInput tag text); render ()))
    window.Content <- holder

  member _.Render() = render ()
  member _.Model with get () = model and set v = model <- v
  member _.Api with get () = api and set v = api <- v
  member _.Renders = renders
  member _.Dispatch(msg: obj) = model <- api.Update model msg; render ()
