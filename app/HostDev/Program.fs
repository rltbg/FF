module Program

open System
open System.IO
open Avalonia
open Avalonia.Controls
open Avalonia.Threading
open Avalonia.X11
open Ui
open Reload

let stamp () = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()

[<EntryPoint>]
let main argv =
  let path = argv.[0]
  let logPath = if argv.Length > 1 then argv.[1] else "/dev/null"
  let log (s: string) = File.AppendAllText(logPath, string (stamp ()) + " " + s + "\n")
  let mutable alc : CoreAlc = Unchecked.defaultof<_>
  let mutable modelType : Type = null
  let mutable runner : Runner = Unchecked.defaultof<_>
  let reload () =
    let t0 = stamp ()
    let a, _, api, mt = load path
    let newType = mt null
    let keep =
      if isNull (box runner) then Choice1Of2 api.Init
      else
        try Choice1Of2 (transplant runner.Model newType)
        with TransplantFailed why -> Choice2Of2 why
    let oldAlc = alc
    alc <- a; modelType <- newType
    match keep with
    | Choice1Of2 m ->
      if not (isNull (box runner)) then runner.Model <- m
      if not (isNull (box runner)) then (runner.Api <- api; runner.Render())
      log ("reloaded model-kept ms=" + string (stamp () - t0))
      api
    | Choice2Of2 why ->
      runner.Api <- api; runner.Model <- api.Init; runner.Render()
      log ("reloaded model-RESET (" + why + ") ms=" + string (stamp () - t0))
      api
    |> fun api ->
      if not (isNull (box oldAlc)) then oldAlc.Unload()
      api
  UiApp.OnReady <- fun lt ->
    let w = Window(Title = "F* MVU", Width = 520.0, Height = 560.0)
    let a, _, api, mt = load path
    alc <- a; modelType <- mt null
    runner <- Runner(api, w)
    lt.MainWindow <- w
    w.Opened.Add(fun _ -> runner.Render(); log "ready")
    let dir = Path.GetDirectoryName(Path.GetFullPath path)
    let fsw = new FileSystemWatcher(dir, Path.GetFileName path)
    fsw.NotifyFilter <- NotifyFilters.LastWrite ||| NotifyFilters.Size ||| NotifyFilters.FileName
    let mutable pending = 0L
    let onEvt (_: obj) =
      log "event"
      let me = stamp ()
      pending <- me
      Threading.Tasks.Task.Delay(150).ContinueWith(fun _ ->
        if pending = me then
          log "change-detected"
          Dispatcher.UIThread.Post(fun () ->
            try reload () |> ignore with e -> log ("reload-error " + e.Message)))
      |> ignore
    // sondage de secours : les réécritures de contenu par MSBuild ne notifient pas inotify ici
    let fileSig () = let fi = FileInfo path in if fi.Exists then fi.LastWriteTimeUtc.Ticks + fi.Length else 0L
    let mutable last = fileSig ()
    let timer = new System.Timers.Timer(250.0)
    timer.Elapsed.Add(fun _ ->
      let n = fileSig ()
      if n <> last then
        last <- n
        onEvt null)
    timer.Start()
    fsw.Changed.Add(onEvt); fsw.Created.Add(onEvt); fsw.Renamed.Add(onEvt)
    fsw.Error.Add(fun e -> log ("fsw-error " + e.GetException().Message))
    fsw.EnableRaisingEvents <- true
    log ("watching " + dir + " " + string fsw.EnableRaisingEvents)
  AppBuilder.Configure<UiApp>()
    .UseX11()
    .UseSkia()
    .UseHarfBuzz()
    .With(X11PlatformOptions(RenderingMode = [| X11RenderingMode.Software |]))
    .StartWithClassicDesktopLifetime([||])
