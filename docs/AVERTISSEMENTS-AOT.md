# Avertissements NativeAOT : origine, correctif, ce qui reste

Mesuré avec `-p:TrimmerSingleWarn=false` (détail de chaque avertissement au lieu d'une ligne par assembly) et, pour remonter à la cause, le graphe de dépendances d'ILC (`-p:IlcGenerateDgmlFile=true`, fichiers `obj/…/native/HostStatic.scan.dgml.xml`). SDK 10.0.403, F# 10 (compilateur 15.2.403), Avalonia 12.1.4.

## Avant (bureau, linux-x64) : `IL2104` et `IL3053` sur FSharp.Core, ≈ 50 avertissements détaillés

Tous dans `printf.fs` (`MakeGenericMethod`, IL2060/IL3050), `sformat.fs` (affichage `%A`, IL2067/IL2070/IL2072/IL2075), `reflect.fs` (`FSharp.Reflection`, IL2055/IL2070/IL3050) et `seq.fs` (`Lazy<T>`, IL2091).

| Cause (remontée par le graphe ILC) | Origine | Correctif | Nature |
|---|---|---|---|
| `Extracted_*_app_msg__ToString`, `…app_model__ToString`, `…app_tab__ToString`, `…app_view_tree__ToString` (etc.), `Ui_Node__ToString`, `Ui_CoreApi__ToString`, `Ui_InputState__ToString` → `ExtraTopLevelOperators.PrintFormatToString` | le compilateur F# génère pour chaque union/enregistrement un `ToString()` qui appelle `sprintf "%+A"` (réflexion) ; ILC le garde car `Object.ToString` est virtuel. Concerne aussi le code **généré** par Custard (non éditable) | option **`--reflectionfree`** du compilateur F# 10 (`<OtherFlags>`, `app/Directory.Build.props`, tous les projets de `app/` sauf `HostDev`) : le `ToString` est écrit champ par champ, sans réflexion | évitable (réglage de compilation) |
| `Seq.init` dans `app/Ui/Lazy.fs` (`LazyRows.GetEnumerator`) → `Lazy<T>` (seq.fs IL2091) | notre code | énumérateur écrit à la main (`IEnumerator` par expression d'objet) | évitable (notre code) |

## Après

- **Bureau (NativeAOT linux-x64) : 0 avertissement**, même avec `TrimmerSingleWarn=false`. Binaire `HostStatic` : 20 730 264 → 19 874 504 octets (−856 Ko, −4,1 %), le moteur printf n'étant plus embarqué.
- **Android (NativeAOT arm64)** : plus aucun avertissement sur FSharp.Core (`IL2104`, `IL3053`). **Reste, hors de notre code, inévitable avec cette version** (.NET Android 36.1 / Mono.Android NativeAOT expérimental, `XA1040`) :
  - `IL3053: Assembly 'Mono.Android' produced AOT analysis warnings`, détaillé en quatre `IL3050` : `Microsoft.Android.Runtime.ManagedTypeManager.GetInvokerTypeCore` (`MakeGenericType`), `Java.Interop.JavaConvert.GetJniHandleConverter` (`MakeGenericType`), `Android.Runtime.JNINativeWrapper.CreateDelegate` (`DynamicMethod`), `Android.Runtime.JNIEnv.MakeArrayType` ;
  - `ILC: Method '[Mono.Android.Runtime]Android.Runtime.RuntimeNativeMethods.monodroid_unhandled_exception(Exception)' will always throw because: Invalid IL or CLR metadata …` et la même chose pour `monodroid_debugger_unhandled_exception(Exception)`. Ces deux méthodes sont des points d'entrée du runtime Mono, absents sous NativeAOT : si le chemin d'exception non gérée les appelle, elles lèvent. À rapprocher du constat d'`docs/ANDROID-DIAG.md` (`mono.android.Runtime.propagateUncaughtException` sans implémentation native). Rien à corriger de notre côté ; à signaler à l'amont si l'utilisateur le décide (aucun ticket déposé, aucun numéro de ticket cité : non lu).

## Programme de test F* (`scripts/ftests.sh`)

Le projet de test généré par Custard (`out/ftests/fs/TMain.fsproj`, hors de `app/`) ne recevait pas `app/Directory.Build.props` : il affichait encore `IL3053` et `IL2104` de FSharp.Core (même cause : `ToString` généré des unions ; son code ne contient aucun `sprintf`). `ftests.sh` passe maintenant `-p:OtherFlags=--reflectionfree` à `dotnet build` (JIT) et `dotnet publish` (AOT). Vérifié : 1 490 342 vérifications, 0 échec, JIT et AOT, aucun avertissement. L'option ne change que la forme du `ToString` des types du test, pas la sémantique mesurée.

## Règle à garder

Pas de `sprintf`, `string`, `%A`, `printfn`, chaîne interpolée typée, `Seq.init`/`Lazy` ni `FSharp.Reflection` dans le code du chemin AOT (voir `CLAUDE.md` §3). Contrôle : `dotnet publish app/HostStatic -c Release -r linux-x64 -p:TrimmerSingleWarn=false` ne doit afficher aucun `warning IL`.
