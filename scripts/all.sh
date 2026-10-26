#!/usr/bin/env bash
# Passe complète depuis un état propre : outils et sources, vérification + extraction, compilation + AOT,
# tests F* (JIT et AOT), test de fumée GUI (AOT et JIT), rechargement à chaud, mutations, matrice d'extraction F*,
# tests amont de F* via le backend F#, balayage d'ulib, construction vers toutes les plateformes, reproductions de défauts.
# (scripts/scale.sh, plus long, est lancé à part.) Aucun test n'est écrit en F# : tout est F* (ftests/, docs/matrix/).
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
dotnet build-server shutdown >/dev/null 2>&1 || true
rm -rf fst/_cache fst/_cache_admit fst/_cache_lax fst/_output out app/*/bin app/*/obj
step() { echo; echo "######## $1"; local t0; t0=$(date +%s); shift; "$@"; echo "######## durée $(( $(date +%s) - t0 )) s"; }
step "setup" scripts/setup.sh
step "sources (F*, Avalonia)" scripts/sources.sh
step "vérification + extraction" scripts/extract.sh full
step "compilation + NativeAOT" scripts/build.sh
step "tests F* (JIT + AOT)" scripts/test.sh
step "GUI AOT" scripts/ui_smoke.sh out/HostStatic/HostStatic
step "GUI JIT" scripts/ui_smoke.sh dotnet app/HostStatic/bin/Release/net10.0/linux-x64/HostStatic.dll
step "rechargement à chaud" scripts/hotreload.sh
step "mutations" scripts/mutate.sh
step "matrice d'extraction F*" scripts/matrix.sh
step "tests amont de F* (backend F#)" scripts/upstream_tests.sh
step "balayage d'ulib + couverture" scripts/ulib_sweep.sh
step "plateformes (bureau ×8, NativeAOT, navigateur, Android, iOS)" scripts/platforms.sh
step "test de fumée navigateur (WebAssembly)" scripts/browser_smoke.sh
step "reproduction char_code" scripts/repro_char_code.sh
step "reproduction type fantôme" scripts/repro_phantom.sh
echo; echo "TOUT OK"
