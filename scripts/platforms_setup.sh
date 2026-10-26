#!/usr/bin/env bash
# Prépare la construction vers les plateformes autres que le bureau Linux : workloads .NET (navigateur, Android) et SDK Android.
# Le SDK Android exige d'accepter ses licences : ce script ne le fait QUE si ACCEPT_ANDROID_LICENSES=1 (acte juridique de l'utilisateur).
# iOS / macOS : les workloads n'existent que sous macOS (`dotnet workload search ios` est vide sous Linux) : rien à préparer ici.
set -euo pipefail
source "$(dirname "$0")/env.sh"
export USER="${USER:-$(id -un)}"   # l'installeur du SDK Android refuse un nom d'utilisateur vide (XAIAD7009)
have() { dotnet workload list 2>/dev/null | grep -q "^$1 "; }
have wasm-tools || dotnet workload install wasm-tools
have android    || dotnet workload install android
if [ ! -d "$ROOT/.tools/android-sdk/platforms" ]; then
  if [ "${ACCEPT_ANDROID_LICENSES:-0}" = 1 ]; then
    dotnet build "$ROOT/app/HostAndroid" -t:InstallAndroidDependencies -f net10.0-android \
      -p:AndroidSdkDirectory="$ROOT/.tools/android-sdk" -p:AcceptAndroidSDKLicenses=True --nologo -v q
  else
    echo "SDK Android absent : relancer avec ACCEPT_ANDROID_LICENSES=1 pour accepter ses licences et l'installer (JDK 17+ requis)."; exit 3
  fi
fi
# NDK r27+ : nécessaire au NativeAOT Android (l'éditeur de liens final est celui du NDK) ; même licence que le SDK
if [ ! -d "$ROOT/.tools/android-sdk/ndk/27.2.12479018" ] && [ "${ACCEPT_ANDROID_LICENSES:-0}" = 1 ]; then
  "$ROOT/.tools/android-sdk/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$ROOT/.tools/android-sdk" "ndk;27.2.12479018" > /dev/null
fi
echo "plateformes prêtes : $(dotnet workload list | awk '/^(wasm-tools|android) /{printf "%s ", $1}') ; SDK Android : $([ -d "$ROOT/.tools/android-sdk/platforms" ] && echo présent || echo absent)"
