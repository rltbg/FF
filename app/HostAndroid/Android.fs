namespace HostAndroid

open System
open System.IO
open System.Threading
open Android.App
open Android.Content.PM
open Android.OS
open Android.Runtime
open Android.Util
open Avalonia
open Avalonia.Android
open Ui

module Diag =
  let tag = "MVU"
  let log (s: string) = Log.Info(tag, s) |> ignore

  /// État du thread principal lu dans /proc : R = il exécute (boucle), S/D = il attend (verrou, E/S) ; utime/stime en ticks.
  let procState () =
    try
      let pid = Process.MyPid()
      let stat = File.ReadAllText(sprintf "/proc/self/task/%d/stat" pid)
      let after = stat.Substring(stat.LastIndexOf(')') + 2).Split(' ')
      let wchan = try File.ReadAllText(sprintf "/proc/self/task/%d/wchan" pid) with _ -> "?"
      "état=" + after.[0] + " utime=" + after.[11] + " stime=" + after.[12] + " wchan=" + wchan
    with e -> "procState : " + e.Message

  /// Chien de garde : toutes les 6 s, journalise l'état et la pile JAVA du thread principal (où il est bloqué dans l'appel natif/JNI).
  /// Démarré avant tout le reste ; temporaire (docs/ANDROID-DIAG.md).
  let startWatchdog () =
    let t =
      Thread((fun () ->
        for i in 1 .. 4 do
          Thread.Sleep 6000
          log (sprintf "chien de garde #%d : thread principal %s" i (procState ()))
          try
            let st = Looper.MainLooper.Thread.GetStackTrace()
            for e in st do log ("  at " + e.ToString())
          with e -> log ("chien de garde : pile Java illisible : " + e.ToString())), IsBackground = true)
    t.Start()

/// Application Android : démarre Avalonia avec UiApp ; la vue principale vient de Shell.useSingleView.
[<Application>]
type MvuApplication(javaReference: nativeint, transfer: JniHandleOwnership) =
  inherit AvaloniaAndroidApplication<UiApp>(javaReference, transfer)
  do
    UiApp.Trace <- Diag.log
    Diag.log "Application : constructeur"
    Diag.startWatchdog ()
  override _.OnCreate() =
    Diag.log "Application.OnCreate : avant"
    base.OnCreate()
    Diag.log "Application.OnCreate : après"
  override _.CustomizeAppBuilder(builder: AppBuilder) : AppBuilder =
    Diag.log "CustomizeAppBuilder"
    Shell.useSingleView ()
    base.CustomizeAppBuilder(builder)

[<Activity(Label = "F* MVU", MainLauncher = true, Exported = true,
           ConfigurationChanges = (ConfigChanges.Orientation ||| ConfigChanges.ScreenSize ||| ConfigChanges.UiMode))>]
type MainActivity() =
  inherit AvaloniaMainActivity()
  do Diag.log "MainActivity : constructeur"
  override _.OnCreate(savedInstanceState: Bundle) =
    Diag.log "MainActivity.OnCreate : avant"
    base.OnCreate(savedInstanceState)
    Diag.log "MainActivity.OnCreate : après"
  override _.OnResume() =
    Diag.log "MainActivity.OnResume"
    base.OnResume()
