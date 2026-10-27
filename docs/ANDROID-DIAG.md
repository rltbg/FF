# Android NativeAOT : écran blanc au lancement (cause trouvée, correctif à valider sur appareil)

## CAUSE (journal `logcat` d'un appareil réel, avec les traces `MVU`)

```
I/MVU: MainActivity.OnCreate : avant → MainView : création / Runner créé / premier rendu fait   (notre code : OK)
E/net.fstar.mvu: Invalid resource ID 0x00000000.
E/AndroidRuntime: java.lang.IllegalStateException: You need to use a Theme.AppCompat theme (or descendant) with this activity.
  at androidx.appcompat.app.AppCompatDelegateImpl.createSubDecor … AppCompatActivity.setContentView … MainActivity.n_onCreate
F/DOTNET: FATAL UNHANDLED EXCEPTION: Java.Lang.RuntimeException: Unable to start activity … ---> Java.Lang.IllegalStateException … Android.App.Activity.SetContentView(View)
E/net.fstar.mvu: No implementation found for void mono.android.Runtime.propagateUncaughtException(java.lang.Thread, java.lang.Throwable) …
```

- **Cause : la `MainActivity` n'avait aucun thème** (évitable : notre code). `AvaloniaActivity` hérite de `AppCompatActivity`, qui exige un thème AppCompat. Correctif : `Theme = "@style/MyTheme.NoActionBar"` sur l'activité + `app/HostAndroid/Resources/values/styles.xml` (parent `Theme.AppCompat.DayNight.NoActionBar`, comme `samples/ControlCatalog.Android` d'Avalonia). Le manifeste de l'APK construit contient bien `android:theme=@style/MyTheme.NoActionBar` (`aapt2 dump xmltree`) ; la CI le vérifie désormais. **Non validé sur appareil à l'écriture.**
- **Pourquoi un écran blanc plutôt qu'un plantage visible** (constat, inévitable avec cette version) : sous .NET Android NativeAOT (expérimental), `mono.android.Runtime.propagateUncaughtException` n'a pas d'implémentation native (« No implementation found … is the library loaded »). L'exception fatale n'est donc pas propagée et le processus reste vivant, bloqué dans la transaction de lancement : MIUI le signale comme `APP_SCOUT_HANG` (message `ActivityThread$H` code 159 = `EXECUTE_TRANSACTION`). Ce n'était pas un blocage de notre code.

## Historique du diagnostic

## Constat (appareil Xiaomi/MIUI de l'utilisateur, APK `fstar-mvu-android-arm64.apk` de la CI, run 40370127417)

- L'APK s'installe, l'app démarre, **écran blanc**, pas de plantage (`logcat -b crash` vide).
- `logcat --pid` : `MIUIScout App: Enter APP_SCOUT_HANG state` ; `Current message: duration=738426ms seq=3 … h=android.app.ActivityThread$H w=159`.
  - `w=159` = `ActivityThread.H.EXECUTE_TRANSACTION` (lancement de l'activité), `seq=3` : l'Application a été créée (message précédent) ; **le thread principal est bloqué (≈ 12 min) dans la transaction de lancement de `MainActivity`**.
- Ce qui s'exécute dans cette transaction (sources `.tools/src/Avalonia/src/Android/Avalonia.Android/AvaloniaActivity.cs`, `AvaloniaMainActivity.cs`) : `OnCreate` → `InitializeAvaloniaView` → `MainViewFactory.Invoke()` (notre fabrique : `Runner` + premier rendu) → `new AvaloniaView(this)` → `SetContentView` → `_view.Content = …`.
- Non déterminé : si le blocage est dans notre code, dans Avalonia, dans le pilote graphique (EGL/GL) ou dans l'interopérabilité Java de NativeAOT (expérimental). On ne sait pas non plus si l'APK Mono fonctionnerait sur cet appareil (non construit en CI, décision de l'utilisateur).

## Instrumentation ajoutée (temporaire)

- Étiquette logcat `MVU` : constructeur et `OnCreate` de l'Application, `CustomizeAppBuilder`, `UiApp.Initialize`, `OnFrameworkInitializationCompleted`, fabrique de la vue (création, `Runner`, premier rendu), constructeur/`OnCreate`/`OnResume` de `MainActivity`. **Le dernier message affiché avant le blocage situe le point d'arrêt.**
- Chien de garde (4 passages, toutes les 6 s) : état du thread principal lu dans `/proc` (`R` = il exécute, `S`/`D` = il attend ; `utime`/`stime` ; `wchan`) et sa pile **Java**.
- Si la fabrique de vue lève une exception, elle s'affiche à l'écran (au lieu d'un écran blanc) et est journalisée.

## Récupérer le journal

```bash
adb install -r fstar-mvu-android-arm64.apk
adb logcat -c
adb shell am start -n net.fstar.mvu/crc64843ec91e4222f84c.MainActivity
sleep 30
adb logcat -d --pid=$(adb shell pidof net.fstar.mvu) -v time > logcat.txt
```
