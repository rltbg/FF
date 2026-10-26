# Compiler vers toutes les plateformes

> **NativeAOT partout ?** Voir [`NATIVEAOT.md`](NATIVEAOT.md) : la documentation exclut la compilation NativeAOT **entre OS** (Windows et macOS/iOS exigent leur propre machine), classe Android « expérimental » (APK NativeAOT construit ici, jamais lancé) et ne prévoit pas le navigateur.

**Objectif de cette étape :** que le même cœur F* et la même interface se **construisent** pour toutes les plateformes qu'Avalonia 12.1.4 prend en
charge, sans rien mesurer ni valider fonctionnellement hors Linux. Résultat de la dernière passe : [`PLATEFORMES-RESULTAT.md`](PLATEFORMES-RESULTAT.md)
(généré par `scripts/platforms.sh`). Aucune des mesures de `REPORT.md` (démarrage, mémoire, rendu) ne vaut pour une autre plateforme.

## Architecture : une colle commune, des têtes minces

```
fst/*.fst ──F*/Custard──> app/Extracted  (F# extrait, 100 % portable : bigint, string, list, byte[])
                              │
app/Ui        (Avalonia noyau seul : Node, Interp, Runner, UiApp)  ← aucune dépendance de plateforme
app/Shell     (toNode, CoreApi, useSingleView, journal/préchargement produits par F*)
   ├── app/UiDesktop  + app/HostStatic   bureau : Windows / macOS / Linux  (Avalonia.Desktop, fenêtre)
   ├── app/HostBrowser                   WebAssembly (Avalonia.Browser, vue unique dans <div id="out">)
   ├── app/HostAndroid                   Android (Avalonia.Android, activité + application)
   └── app/HostIOS                       iOS (Avalonia.iOS, délégué d'application)
app/HostDev  (rechargement à chaud, réflexion, JIT) : bureau seulement, hors livraison
```
`UiApp.OnFrameworkInitializationCompleted` choisit selon le cycle de vie d'Avalonia : fenêtre de bureau (`IClassicDesktopStyleApplicationLifetime`),
fabrique de vue Android (`IActivityApplicationLifetime`), vue unique iOS/navigateur (`ISingleViewApplicationLifetime`). `Runner` accepte tout
`ContentControl` (une `Window` ou une `UserControl`). Rien de la logique n'est dupliqué : une tête, c'est 10 à 30 lignes.

## Ce qui se construit ici (Linux x86_64)

| Cible | Comment | Notes |
|---|---|---|
| Windows x64, arm64 ; macOS x64, arm64 ; Linux x64, arm64 ; Linux musl x64, arm64 | publication autonome JIT **croisée** (`dotnet publish -r <rid> --self-contained`) | l'en-tête de l'exécutable (MZ / Mach-O / ELF) et la présence des bibliothèques natives Skia/HarfBuzz sont vérifiés |
| Linux x64 NativeAOT | `dotnet publish -r linux-x64` | **seulement le RID de la machine** : le compilateur natif ne cross-compile pas entre OS |
| Navigateur (WebAssembly) | workload `wasm-tools`, `WasmBuildNative` | exécuté dans Chromium (Playwright, WebGL logiciel) : `scripts/browser_smoke.sh` |
| Android | workload `android` + SDK Android + JDK 17+ | APK signé de 32 Mo (AOT inclus pour arm64 et x86_64) ; **jamais installé ni lancé** (pas d'émulateur) |

Préparation : `scripts/platforms_setup.sh` (workloads ; le SDK Android exige d'accepter ses licences : `ACCEPT_ANDROID_LICENSES=1`, jamais par défaut).
Construction : `scripts/platforms.sh [cible …]`.

## Ce qui ne se construit PAS ici, et pourquoi

| Cible | Raison |
|---|---|
| **iOS** (`app/HostIOS`) | exige macOS + Xcode + le workload `ios` : `dotnet workload search ios` ne renvoie rien sous Linux. Le projet est écrit d'après `samples/ControlCatalog.iOS` d'Avalonia 12.1.4 et **n'a jamais été compilé** ; `scripts/platforms.sh ios` le construit sur un Mac. |
| NativeAOT pour Windows, macOS, Linux arm64, musl | le compilateur natif (ILCompiler) exige l'OS cible (et sa chaîne de liaison) : à lancer sur chaque OS (`dotnet publish -r <rid>` avec `PublishAot=true`, qui est la valeur par défaut de `HostStatic.fsproj`). |
| macOS Catalyst, tvOS, Tizen | non prévus (Avalonia a des échantillons Catalyst et tvOS ; même démarche que `HostIOS`). |

## Ce qui est vérifié, et ce qui ne l'est pas

- **Vérifié** : la construction aboutit ; le bureau Linux x64 (JIT et NativeAOT) passe le smoke GUI complet ; le navigateur charge la page, crée le canvas,
  n'émet aucune erreur et le clic sur « + » affiche `Valeur : 2` (capture `shots/browser/1_apres_clics.png`) : le modèle F* tourne bien en WebAssembly.
- **Non vérifié** : tout lancement sous Windows, macOS, Android (APK jamais installé), iOS ; le rendu (WebGL/Skia/Metal/D3D) hors Linux et navigateur logiciel ;
  les performances, la mémoire, le démarrage ; le tactile ; le clavier virtuel ; le comportement de `ScrollViewer`/`ListBox` virtualisée hors Linux (le contournement
  du `ScrollContentPresenter` est dans `Ui`, donc embarqué, mais non éprouvé ailleurs).
- **Différences connues à prévoir** : le navigateur et iOS n'ont pas de fenêtre (vue unique) ; la glyphe « ● » de la barre d'onglets s'affiche en carré dans la police de repli du
  navigateur (visible sur la capture) ; sur le navigateur le `TextBox` et le focus passent par le DOM ; sur mobile, la liste de 100 000 lignes dépend de la fluidité du défilement tactile (non mesurée).
- **Points d'attention du code** : `MVU_TRACE`/`MVU_PRELOAD` (variables d'environnement) n'existent pas dans un navigateur ni sur mobile ; la vue y est rendue immédiatement
  (pas d'événement `Opened`) ; `InvariantGlobalization` est activé partout.
