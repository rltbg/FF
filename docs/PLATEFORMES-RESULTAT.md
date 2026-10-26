# Plateformes : ce qui se compile (généré par scripts/platforms.sh, 2026-10-26)

| Cible | Mode | État | Détail |
|---|---|---|---|
| `win-x64` | JIT | BUILT | 207M ; 9 bibliothèques natives (Skia/HarfBuzz…) |
| `win-arm64` | JIT | BUILT | 216M ; 9 bibliothèques natives (Skia/HarfBuzz…) |
| `osx-x64` | JIT | BUILT | 107M ; 7 bibliothèques natives (Skia/HarfBuzz…) |
| `osx-arm64` | JIT | BUILT | 114M ; 7 bibliothèques natives (Skia/HarfBuzz…) |
| `linux-x64` | JIT | BUILT | 104M ; 6 bibliothèques natives (Skia/HarfBuzz…) |
| `linux-arm64` | JIT | BUILT | 110M ; 6 bibliothèques natives (Skia/HarfBuzz…) |
| `linux-musl-x64` | JIT | BUILT | 112M ; 6 bibliothèques natives (Skia/HarfBuzz…) |
| `linux-musl-arm64` | JIT | BUILT | 118M ; 6 bibliothèques natives (Skia/HarfBuzz…) |
| `linux-x64` | NativeAOT | BUILT | 78M (RID de cette machine seulement) |
| `browser-wasm` | WASM | BUILT | 24M ; wwwroot/ à servir en HTTP |
| `android` | APK | BUILT | 32M ; net.fstar.mvu-Signed.apk |
| `ios-arm64` | app | SAUTÉ | exige macOS + Xcode + workload ios ; projet app/HostIOS écrit, jamais compilé |
