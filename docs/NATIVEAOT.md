# NativeAOT sur toutes les plateformes : ce que dit la documentation, ce qui a été essayé

Lecture faite le 2026-10-26. Les citations viennent des pages indiquées ; ce qui est **essayé ici** est marqué « essayé ». Rien n'a été lancé hors Linux.

## 1. Règles générales (Microsoft, [Native AOT deployment overview](https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/))

- `PublishAot=true` dans le projet exécutable, puis `dotnet publish -r <RID> -c Release` (pas `dotnet build -t:Publish`). `IsAotCompatible=true` dans **chaque** bibliothèque (analyseurs trim/AOT).
- Prérequis du compilateur natif : Windows = Visual Studio avec « Desktop development with C++ » ; Linux = `clang` + `zlib1g-dev` (Ubuntu) ; macOS = Command Line Tools de Xcode.
- Limites : pas de chargement dynamique d'assemblies, pas de `Reflection.Emit`, trimming obligatoire, `System.Linq.Expressions` interprété, un binaire Linux ne tourne que sur la même glibc ou plus récente.
- Cibles prises en charge (.NET 9+) : Windows x64/arm64/x86 ; Linux x64/arm64/arm ; macOS x64/arm64 ; iOS arm64, iOSSimulator x64/arm64, tvOS, MacCatalyst x64/arm64 ; **Android x64/arm64/arm : « Experimental, no built-in Java interop »**.
- **Pas de navigateur/WebAssembly** dans cette table.

## 2. Compilation croisée ([Cross-compilation](https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/cross-compile))

> « Native AOT does not support cross-OS compilation. » (aucun SDK macOS utilisable depuis Windows/Linux, ni Windows depuis Linux/macOS)

Seule la compilation **croisée d'architecture** (x64 ↔ arm64) est possible, avec la chaîne native de la cible : Windows (composants VS « ARM64/ARM64EC build tools » ou « x64/x86 build tools »), macOS (x64 et arm64 sont dans l'installation Xcode par défaut), Linux (éditeur de liens croisé type `clang`, `objcopy`/`strip` de la cible, objets du runtime C et de zlib de la cible ; exemple Ubuntu 22.04 donné par la page, « not documented or guaranteed »).

**Conséquence : un NativeAOT pour Windows exige une machine Windows, un NativeAOT pour macOS/iOS/Mac Catalyst une machine macOS.** Depuis Linux, seuls Linux (x64, et arm64 avec chaîne croisée) et Android (via le NDK, voir §4) sont atteignables.

## 3. Avalonia ([Native AOT](https://docs.avaloniaui.net/docs/deployment/native-aot))

`PublishAot` sur l'exécutable seulement, `IsAotCompatible` partout ; XAML compilé (`x:CompileBindings`), pas de XAML chargé à l'exécution, ressources en `AvaloniaResource`, pas de localisation de services par réflexion ; erreurs de réflexion → `TrimmerRootAssembly`. La page ne donne pas de liste par plateforme et renvoie à la table de Microsoft.
Ce projet n'a **ni XAML, ni liaisons, ni `ViewLocator`** : les contrôles sont créés en code (`Interp.fs`), ce qui est le cas le plus simple pour le trimming.
Le [billet Avalonia 12](https://avaloniaui.net/blog/avalonia-12) annonce, pour Android, un démarrage de 1 960 ms ramené à 460 ms « avec NativeAOT » (sans détails ni limites). Une [discussion Avalonia](https://github.com/AvaloniaUI/Avalonia/discussions/17738) (2024, avant Avalonia 12) rapporte l'échec « Cross-OS native compilation is not supported » en essayant `PublishAot` pour Android sans le bon réglage.

## 4. Android ([build-properties de .NET for Android](https://github.com/dotnet/android/blob/main/Documentation/docs-mobile/building-apps/build-properties.md))

- `PublishAot=true` sélectionne le runtime NativeAOT pour une publication ; statut : **expérimental** ; RID `android-arm`, `android-arm64`, `android-x64`.
- **Exige le NDK Android** (l'édition de liens finale utilise `ld.lld`, `llvm-objcopy` du NDK ; propriété `AndroidNdkDirectory`) ; Uno Platform indique NDK **r27 ou plus**.
- `AndroidCodegenTarget` doit être `XAJavaInterop1` ; `EnableLLVM`, `RunAOTCompilation`, `AotAssemblies` sont refusés (`XA1044`) ; l'avertissement `XA1040` annonce l'expérimental (`EnablePreviewFeatures=true`).
- Des tickets rapportent des échecs de publication NativeAOT sous .NET 10 (liens libc++ du NDK ; [dotnet/android#10587](https://github.com/dotnet/android/issues/10587), fermé sans correctif confirmé).
- **Essayé ici** (Linux x64, NDK r27c, SDK 36, workload android 36.1.118) : `dotnet publish app/HostAndroid -r android-arm64|android-x64 -p:AndroidNativeAot=true …` **aboutit** : APK signé de 19–20 Mo contenant une seule bibliothèque native `libHostAndroid.so` (code géré compilé en natif, pas de Mono, pas de DLL), Skia et HarfBuzz. **Jamais installé ni lancé** (pas d'émulateur) : l'interopérabilité Java d'Avalonia.Android sous NativeAOT est donc **non vérifiée**.

## 5. iOS, tvOS, Mac Catalyst ([iOS-like platforms](https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/ios-like-platforms/), [MAUI](https://learn.microsoft.com/en-us/dotnet/maui/deployment/nativeaot))

Pris en charge depuis .NET 9. Pour un projet à TFM propre à l'OS (`net10.0-ios`) : `PublishAot` conditionné à l'identifiant de plateforme (jamais à la configuration), puis `dotnet publish -f net10.0-ios -r ios-arm64` (simulateur : `iossimulator-arm64|x64` ; Catalyst : `maccatalyst-arm64|x64`). Il faut un Mac (Xcode). L'interpréteur Mono est incompatible. Heap analysis non supportée. Uno signale que `PublishAot` global pose problème pour iOS (dotnet/sdk#21877) : le conditionner.
**Non essayé** : aucun Mac. `app/HostIOS` n'a jamais été compilé.

## 6. Navigateur / WebAssembly

NativeAOT n'est **pas** une cible officielle pour `browser-wasm` (absent de la table §1). La voie officielle pour le navigateur est l'**AOT Mono pour WebAssembly** (workload `wasm-tools`, `RunAOTCompilation`), ce qui n'est pas NativeAOT. NativeAOT-LLVM existe dans dotnet/runtimelab (expérimental, hors produit). Avalonia indique que WebAssembly est une cible, sans mention de NativeAOT.

**Mesuré ici (Mono AOT, `RunAOTCompilation=true`, même code, Chromium headless sous Linux, rendu logiciel, serveur local) :**

| | interprète Mono (défaut) | Mono AOT |
|---|---|---|
| Publication | ≈ 1 min | ≈ 6 min |
| `_framework` (disque / transfert brotli) | 23 Mo / 4,2 Mo | 52 Mo / 7,5 Mo |
| Canvas créé après chargement | 1,25–1,7 s | 1,4–1,5 s (pas d'avantage visible) |
| Clic « Hacher le texte (F*) » → résultat affiché (texte de 1 Mo généré et haché par F*) | 330–410 ms | 140–175 ms |

Le gain de l'AOT Mono se voit sur le **calcul** (≈ ×2,3 ici), pas sur le chargement ; il coûte presque le double en téléchargement. À titre de repère, le même hachage dure 3 ms en NativeAOT sur le bureau (REPORT §7) : WebAssembly reste ≈ 40 à 100 fois plus lent que le natif, AOT compris. Mesures de ce conteneur uniquement, sur trois essais ; la mesure inclut le délai des captures d'écran.

## 7. Bilan par plateforme

| Plateforme | NativeAOT possible ? | Où le construire | État dans ce dépôt |
|---|---|---|---|
| Linux x64 | oui | Linux x64 | **construit et testé** (smoke GUI complet) |
| Linux arm64, arm | oui (arch croisée) | Linux avec clang + sysroot/zlib de la cible, ou machine arm64 | non essayé (apt disponible, paquets croisés à installer) |
| Linux musl | oui (sur Alpine ou chaîne musl) | Alpine / musl | non essayé |
| Windows x64/arm64/x86 | oui | **machine Windows** + VS C++ (arm64↔x64 croisé possible là) | non essayé : impossible depuis Linux |
| macOS x64/arm64 | oui | **machine macOS** + Xcode | non essayé : impossible depuis Linux |
| iOS / Mac Catalyst / tvOS | oui (.NET 9+) | **machine macOS** + Xcode + workload | `HostIOS` écrit, non compilé |
| Android arm64/x64/arm | **expérimental** | Linux/Windows/macOS avec NDK r27+ | **APK construit** (arm64, x64), jamais lancé ; `arm` non essayé |
| Navigateur | **non** (Mono WASM AOT à la place) | tout OS avec `wasm-tools` | construit en Mono WASM sans AOT natif ; AOT Mono non essayé |

## 8. Ce qui reste à décider ou à faire

1. Machines Windows et macOS (ou runners) pour construire et tester le NativeAOT desktop/iOS/Catalyst : sans elles, ces cibles resteront « écrites, non construites ». (La décision « pas de GitHub Actions » exclut les runners hébergés par ce moyen ; une machine ou une VM par OS convient : `scripts/platforms.sh <rid>` est le point d'entrée.)
2. Tester l'APK NativeAOT sur un émulateur ou un appareil (interop Java).
3. Linux arm64 en croisé : installer `gcc-aarch64-linux-gnu`, `binutils-aarch64-linux-gnu`, `zlib1g-dev:arm64` (modifie le système).
4. Navigateur : choisir entre rester en Mono WASM (non AOT), activer l'AOT Mono (`RunAOTCompilation`, bundle plus gros, démarrage plus rapide), ou attendre un NativeAOT-LLVM officiel.
