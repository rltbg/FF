namespace HostAndroid

open Android.App
open Android.Content.PM
open Android.Runtime
open Avalonia
open Avalonia.Android
open Ui

/// Application Android : démarre Avalonia avec UiApp ; la vue principale vient de Shell.useSingleView.
[<Application>]
type MvuApplication(javaReference: nativeint, transfer: JniHandleOwnership) =
  inherit AvaloniaAndroidApplication<UiApp>(javaReference, transfer)
  override _.CustomizeAppBuilder(builder: AppBuilder) : AppBuilder =
    Shell.useSingleView ()
    base.CustomizeAppBuilder(builder)

[<Activity(Label = "F* MVU", MainLauncher = true, Exported = true,
           ConfigurationChanges = (ConfigChanges.Orientation ||| ConfigChanges.ScreenSize ||| ConfigChanges.UiMode))>]
type MainActivity() =
  inherit AvaloniaMainActivity()
