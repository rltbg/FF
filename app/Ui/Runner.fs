namespace Ui

open System
open Avalonia
open Avalonia.Controls
open Avalonia.Controls.ApplicationLifetimes
open Avalonia.Themes.Fluent

type UiApp() =
  inherit Application()
  /// Bureau (Windows, macOS, Linux) : la fenêtre est créée ici, le callback de StartWithClassicDesktopLifetime s'exécute
  /// avant l'initialisation de la plateforme (doc : "modify the lifetime before application started").
  static member val OnReady : IClassicDesktopStyleApplicationLifetime -> unit = ignore with get, set
  /// Plateformes à vue unique (Android, iOS, navigateur) : fabrique de la vue principale (voir Shell.fs).
  static member val MainView : unit -> Control = (fun () -> null) with get, set
  /// Journal de démarrage (par défaut : rien). La tête Android y branche logcat pour situer un blocage au démarrage (voir docs/ANDROID-DIAG.md).
  static member val Trace : string -> unit = ignore with get, set
  override this.Initialize() =
    UiApp.Trace "UiApp.Initialize"
    this.Styles.Add(FluentTheme())
    UiApp.Trace "UiApp.Initialize : thème ajouté"
  override this.OnFrameworkInitializationCompleted() =
    UiApp.Trace ("UiApp.OnFrameworkInitializationCompleted, lifetime = " + (if isNull this.ApplicationLifetime then "null" else this.ApplicationLifetime.GetType().Name))
    // Ordre : Android implémente à la fois IActivityApplicationLifetime et ISingleViewApplicationLifetime
    // (MainView « n'y est pas pleinement supporté », source Avalonia.Android/ApplicationLifetime.cs) : la fabrique d'abord.
    match this.ApplicationLifetime with
    | :? IClassicDesktopStyleApplicationLifetime as lt -> UiApp.OnReady lt
    | :? IActivityApplicationLifetime as a -> a.MainViewFactory <- Func<Control>(fun () -> UiApp.MainView ())
    | :? ISingleViewApplicationLifetime as v -> v.MainView <- UiApp.MainView ()
    | _ -> ()
    base.OnFrameworkInitializationCompleted()

/// Boucle MVU : un modèle opaque et un cœur interchangeable (rechargement à chaud).
/// `root` : une Window (bureau) ou la vue principale (Android, iOS, navigateur) : tout ContentControl.
type Runner(initial: CoreApi, root: ContentControl) as this =
  let mutable api = initial
  let mutable model = initial.Init
  let holder = ScrollViewer()
  /// Panneau STABLE placé une fois pour toutes dans le ScrollViewer. Avalonia 12.1.4 : ScrollContentPresenter
  /// mémorise le contenu présent au premier Measure (`_scrollSnapPointsInfo`, drapeau `_isSnapPointsUpdated`
  /// à usage unique) et ne le rafraîchit jamais quand le contenu est remplacé : remplacer le contenu du
  /// ScrollViewer retiendrait donc la première racine (et, via Control.Tag, les msg de l'ancien assembly,
  /// ce qui empêchait le déchargement du premier AssemblyLoadContext). On ne remplace que l'enfant de ce panneau.
  let host = StackPanel(Margin = Thickness 16.0)
  let mutable renders = 0
  let interp =
    Interp((fun msg -> this.Dispatch msg),
           (fun tag text -> this.Dispatch(api.MsgOfInput tag text)),
           (fun i -> this.Dispatch(api.MsgOfSelect i)),
           (fun src -> this.Dispatch(api.MsgOfHash src)),
           (fun src i -> api.BigItem src i),
           (fun src s -> api.BigIndex src s))

  let mutable lastRenderMs = 0.0

  let render () =
    let t0 = Diagnostics.Stopwatch.GetTimestamp()
    let root = interp.Render(api.View model)
    if host.Children.Count <> 1 || not (obj.ReferenceEquals(host.Children.[0], root)) then
      host.Children.Clear()
      host.Children.Add root
    renders <- renders + 1
    lastRenderMs <- Diagnostics.Stopwatch.GetElapsedTime(t0).TotalMilliseconds
    this.OnRender model

  do
    holder.Content <- host
    root.Content <- holder

  /// Appelé après chaque rendu avec le modèle (journal de test).
  member val OnRender : obj -> unit = ignore with get, set
  member _.Render() = render ()
  member _.Model = model
  member _.CurrentApi = api
  /// Durée du dernier rendu (vue F* + réconciliation Avalonia), en ms.
  member _.LastRenderMs = lastRenderMs
  /// Applique des messages sans rendre (préchargement de test).
  member _.Preload(msgs: obj list) = for m in msgs do model <- api.Update model m
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
