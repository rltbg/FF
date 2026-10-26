module Program

open Ui

/// Tête BUREAU (Windows, macOS, Linux ; JIT ou NativeAOT). Toute la colle est dans Shell.fs.
[<EntryPoint>]
let main argv =
  Startup.run argv (fun lt ->
    let w = Startup.newWindow ()
    let r = Runner(Shell.api, w)
    Shell.attachTestHooks r
    lt.MainWindow <- w
    w.Opened.Add(fun _ -> r.Render()))
