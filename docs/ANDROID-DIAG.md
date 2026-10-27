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

## Validation sur appareil (Xiaomi/MIUI, APK du run 40446612884)

- **Écran blanc corrigé** : le journal va jusqu'à `MainActivity.OnCreate : après` puis `MainActivity.OnResume`, avec rendu (`vri.reportDrawFinished`, surface créée) et sans `FATAL EXCEPTION` ; l'utilisateur confirme que l'affichage fonctionne.
- **Nouveau problème rapporté par l'utilisateur : des plantages après l'affichage.** Le journal reçu s'arrête 2,7 s après le lancement et ne contient aucun plantage : le moment et la cause sont à déterminer (clic, défilement, saisie, mise en arrière-plan, rotation ?). Bruit sans rapport dans le journal : `avc: denied … minor_window_app`, `Unable to match the desired swap behavior`, `Invalid resource ID 0x00000000`, `Skipped 34 frames` (démarrage).

## Validation finale sur appareil

Après retrait du chien de garde (APK du run 40447629446), l'utilisateur rapporte : « on n'a plus de soucis maintenant, ça fonctionne niquel » (affichage et utilisation corrects, plus de plantage). Confirme indirectement l'hypothèse ci-dessous. Non mesuré : durée d'utilisation, autres appareils.

## Plantage à +6 s : provoqué (très probablement) par le chien de garde de diagnostic, retiré

Le journal complet du lancement de 04:57:30 (pid 15971) contient : `am_crash [2523,0,net.fstar.mvu,…,Native crash,Aborted,…]` à 04:57:36.771, soit **6,0 s après le lancement** ; `tombstone_08` à la même seconde ; `am_proc_died` ; **aucune ligne `chien de garde` n'a été journalisée avant la mort du processus**. Le premier passage du chien de garde (thread .NET d'arrière-plan appelant `Log.Info`, lisant `/proc`, puis `Looper.MainLooper.Thread.GetStackTrace()` par JNI) tombe exactement à +6 s. Un tombstone de 04:48:47 (+6,5 s après le lancement de 04:48:40) va dans le même sens. Conclusion **probable, non prouvée** (le contenu de la tombstone n'est pas dans le journal) : un appel JNI depuis un thread d'arrière-plan .NET fait abandonner le processus sous .NET Android NativeAOT (expérimental). Cause : **notre instrumentation (évitable)**. Correctif : chien de garde supprimé ; les traces `MVU` restent (thread principal, elles fonctionnent). À confirmer : l'app doit rester vivante bien au-delà de 6 s.

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
