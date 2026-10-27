namespace HostAndroid

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

/// Application Android : démarre Avalonia avec UiApp ; la vue principale vient de Shell.useSingleView.
[<Application>]
type MvuApplication(javaReference: nativeint, transfer: JniHandleOwnership) =
  inherit AvaloniaAndroidApplication<UiApp>(javaReference, transfer)
  do
    UiApp.Trace <- Diag.log
    Diag.log "Application : constructeur"
  override _.OnCreate() =
    Diag.log "Application.OnCreate : avant"
    base.OnCreate()
    Diag.log "Application.OnCreate : après"
  override _.CustomizeAppBuilder(builder: AppBuilder) : AppBuilder =
    Diag.log "CustomizeAppBuilder"
    Shell.useSingleView ()
    base.CustomizeAppBuilder(builder)

[<Activity(Label = "F* MVU", Theme = "@style/MyTheme.NoActionBar", MainLauncher = true, Exported = true,
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
