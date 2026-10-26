#!/usr/bin/env bash
# Passe complète depuis un état propre : outils, vérification + extraction, compilation + AOT,
# tests JIT/AOT, test de fumée GUI (AOT et JIT), rechargement à chaud, mutations.
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
dotnet build-server shutdown >/dev/null 2>&1 || true
rm -rf fst/_cache fst/_cache_admit fst/_cache_lax fst/_output out app/*/bin app/*/obj
step() { echo; echo "######## $1"; local t0; t0=$(date +%s); shift; "$@"; echo "######## durée $(( $(date +%s) - t0 )) s"; }
step "setup" scripts/setup.sh
step "vérification + extraction" scripts/extract.sh full
step "compilation + NativeAOT" scripts/build.sh
step "tests JIT + AOT" scripts/test.sh
step "GUI AOT" scripts/ui_smoke.sh out/HostStatic/HostStatic
step "GUI JIT" scripts/ui_smoke.sh dotnet app/HostStatic/bin/Release/net10.0/linux-x64/HostStatic.dll
step "rechargement à chaud" scripts/hotreload.sh
step "mutations" scripts/mutate.sh
echo; echo "TOUT OK"
