#!/usr/bin/env bash
# Compile l'application vers TOUTES les plateformes qu'Avalonia 12 prend en charge. Aucune mesure (voir docs/PLATEFORMES.md) : on vérifie
# seulement que la construction aboutit et que les artefacts attendus existent. Sortie : logs/platforms.tsv, docs/PLATEFORMES.md.
#   bureau   : win-x64 win-arm64 osx-x64 osx-arm64 linux-x64 linux-arm64 (+ linux-musl-x64, linux-musl-arm64) :
#              publication autonome (self-contained), JIT, depuis n'importe quel OS (la publication croisée n'exige pas de chaîne native) ;
#   aot      : NativeAOT, seulement pour le RID de la machine (le compilateur natif ne cross-compile pas entre OS) ;
#   browser  : WebAssembly (workload wasm-tools) ;  android : APK signé (workload android + SDK) ;  ios : macOS + Xcode seulement.
# usage : platforms.sh [cible ...]   (cibles : les RID ci-dessus, aot, browser, android, ios ; défaut : toutes)
set -uo pipefail
source "$(dirname "$0")/env.sh"
export USER="${USER:-$(id -un)}"
OUT="$ROOT/out/platforms"; mkdir -p "$OUT" "$ROOT/logs"
ASDK="$ROOT/.tools/android-sdk"
HOSTRID=$(dotnet --info | awk '/RID:/{print $2; exit}')
RIDS=(win-x64 win-arm64 osx-x64 osx-arm64 linux-x64 linux-arm64 linux-musl-x64 linux-musl-arm64)
targets=("$@"); [ ${#targets[@]} -eq 0 ] && targets=("${RIDS[@]}" aot browser android android-naot ios)
: > "$ROOT/logs/platforms.tsv"
rec() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" | tee -a "$ROOT/logs/platforms.tsv" >/dev/null; printf '%-18s %-9s %-8s %s\n' "$1" "$2" "$3" "$4"; }
size() { du -sh "$1" 2>/dev/null | cut -f1; }
desktop() { # rid
  local rid=$1 d="$OUT/$1" exe; rm -rf "$d"
  if dotnet publish "$ROOT/app/HostStatic" -c Release -r "$rid" --self-contained -p:PublishAot=false --nologo -o "$d" > "$OUT/$rid.log" 2>&1; then
    case $rid in win-*) exe=HostStatic.exe;; *) exe=HostStatic;; esac
    # bibliothèques natives d'Avalonia attendues pour ce RID (Skia, HarfBuzz)
    local nat; nat=$(ls "$d" | grep -ciE 'skia|harfbuzz|av_libglesv2|libAvaloniaNative')
    # format de l'exécutable : PE (MZ), Mach-O 64 bits (cffaedfe), ELF (7f454c46)
    local magic want; magic=$(head -c4 "$d/$exe" 2>/dev/null | od -An -tx1 | tr -d ' \n')
    case $rid in win-*) want=4d5a;; osx-*) want=cffaedfe;; *) want=7f454c46;; esac
    if [ -f "$d/$exe" ] && [ "$nat" -ge 2 ] && [[ "$magic" == $want* ]]; then rec "$rid" JIT BUILT "$(size "$d") ; $nat bibliothèques natives (Skia/HarfBuzz…)"
    else rec "$rid" JIT INCOMPLET "exécutable $exe (en-tête $magic, attendu $want) ou bibliothèques natives absents (voir out/platforms/$rid.log)"; fi
  else rec "$rid" JIT ÉCHEC "$(grep -m1 -E 'error' "$OUT/$rid.log" | sed 's|.*/||' | cut -c1-160)"; fi
}
for t in "${targets[@]}"; do
  case $t in
    win-*|osx-*|linux-*) desktop "$t" ;;
    aot)
      d="$OUT/aot-$HOSTRID"; rm -rf "$d"
      if dotnet publish "$ROOT/app/HostStatic" -c Release -r "$HOSTRID" --nologo -o "$d" > "$OUT/aot.log" 2>&1 && [ -x "$d/HostStatic" -o -f "$d/HostStatic.exe" ]; then rec "$HOSTRID" NativeAOT BUILT "$(size "$d") (RID de cette machine seulement)"
      else rec "$HOSTRID" NativeAOT ÉCHEC "$(grep -m1 -E 'error' "$OUT/aot.log" | cut -c1-160)"; fi ;;
    browser|browser-aot)
      # bin/ et obj/ sont vidés : réutiliser les objets d'un build AOT pour un build sans AOT (ou l'inverse) donne un runtime qui échoue
      # au chargement (« MONO interpreter: NIY … OutOfMemoryException:.ctor », observé)
      rm -rf "$ROOT/app/HostBrowser/bin" "$ROOT/app/HostBrowser/obj"
      aotflag=""; [ "$t" = browser-aot ] && aotflag="-p:RunAOTCompilation=true"
      d="$OUT/$t"; rm -rf "$d"
      if dotnet publish "$ROOT/app/HostBrowser" -c Release $aotflag --nologo -o "$d" > "$OUT/$t.log" 2>&1 && [ -f "$d/wwwroot/index.html" ] && ls "$d"/wwwroot/_framework/dotnet*.js >/dev/null 2>&1; then rec browser-wasm "$([ "$t" = browser-aot ] && echo "Mono AOT" || echo interprète)" BUILT "$(size "$d") ; wwwroot/ à servir en HTTP"
      else rec browser-wasm WASM ÉCHEC "$(grep -m1 -E 'error' "$OUT/$t.log" | cut -c1-160) (workload wasm-tools : scripts/platforms_setup.sh)"; fi ;;
    android)
      d="$OUT/android"; rm -rf "$d"
      if [ ! -d "$ASDK/platforms" ]; then rec android APK SAUTÉ "SDK Android absent : ACCEPT_ANDROID_LICENSES=1 scripts/platforms_setup.sh"
      elif dotnet publish "$ROOT/app/HostAndroid" -c Release --nologo -p:AndroidSdkDirectory="$ASDK" -o "$d" > "$OUT/android.log" 2>&1 && ls "$d"/*-Signed.apk >/dev/null 2>&1; then rec android APK BUILT "$(ls "$d"/*-Signed.apk | head -1 | xargs du -h | cut -f1) ; $(basename "$(ls "$d"/*-Signed.apk | head -1)")"
      else rec android APK ÉCHEC "$(grep -m1 -E 'error' "$OUT/android.log" | sed 's|.*/||' | cut -c1-160)"; fi ;;
    android-naot)
      NDK="$ASDK/ndk/27.2.12479018"
      for abi in android-arm64 android-x64; do
        d="$OUT/android-naot-$abi"; rm -rf "$d"
        if [ ! -d "$NDK" ]; then rec "$abi" NativeAOT SAUTÉ "NDK r27 absent : ACCEPT_ANDROID_LICENSES=1 scripts/platforms_setup.sh"
        elif dotnet publish "$ROOT/app/HostAndroid" -c Release -r "$abi" -p:AndroidNativeAot=true --nologo -p:AndroidSdkDirectory="$ASDK" -p:AndroidNdkDirectory="$NDK" -o "$d" > "$OUT/$abi-naot.log" 2>&1 && ls "$d"/*-Signed.apk >/dev/null 2>&1; then
          rec "$abi" NativeAOT BUILT "$(du -h "$d"/*-Signed.apk | head -1 | cut -f1) ; $(unzip -l "$d"/*-Signed.apk | grep -c 'libHostAndroid.so') lib native managée ; expérimental, jamais lancé"
        else rec "$abi" NativeAOT ÉCHEC "$(grep -m1 -E 'error' "$OUT/$abi-naot.log" | sed 's|.*/||' | cut -c1-160)"; fi
      done ;;
    ios)
      if [ "$(uname)" != Darwin ]; then rec ios-arm64 app SAUTÉ "exige macOS + Xcode + workload ios ; projet app/HostIOS écrit, jamais compilé"
      elif dotnet build "$ROOT/app/HostIOS" -c Release --nologo > "$OUT/ios.log" 2>&1; then rec ios-arm64 app BUILT "voir out/platforms/ios.log"
      else rec ios-arm64 app ÉCHEC "$(grep -m1 -E 'error' "$OUT/ios.log" | cut -c1-160)"; fi ;;
    *) echo "cible inconnue : $t" ;;
  esac
done
echo; echo "résumé : $(cut -f3 "$ROOT/logs/platforms.tsv" | sort | uniq -c | tr '\n' ' ')"
if [ $# -eq 0 ]; then
  { echo "# Plateformes : ce qui se compile (généré par scripts/platforms.sh, $(date +%F))"; echo
    echo "| Cible | Mode | État | Détail |"; echo "|---|---|---|---|"
    awk -F'\t' '{printf "| `%s` | %s | %s | %s |\n", $1,$2,$3,$4}' "$ROOT/logs/platforms.tsv"; } > "$ROOT/docs/PLATEFORMES-RESULTAT.md"
  ! grep -qP '\tÉCHEC\t|\tINCOMPLET\t' "$ROOT/logs/platforms.tsv"
fi
