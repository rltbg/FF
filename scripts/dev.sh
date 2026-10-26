#!/usr/bin/env bash
# Environnement de DÉVELOPPEMENT : tout en JIT, sur la machine courante, sans NativeAOT ni autres plateformes.
# Le NativeAOT et les autres OS/architectures sont construits par la CI (docs/CI.md), pas ici.
#   dev.sh [run]          construit (JIT, Debug) puis lance la fenêtre bureau (HostStatic)
#   dev.sh watch [mode]   fenêtre avec RECHARGEMENT À CHAUD : à chaque modification de fst/*.fst, vérification F* -> extraction -> Extracted.dll,
#                         recharge dans la fenêtre sans la fermer (mode : lax (défaut, le plus rapide), admit, full)
#   dev.sh aot            NativeAOT pour CETTE machine uniquement (ce que fait la CI par plateforme), dans out/aot-<rid>/
# Prérequis : scripts/setup.sh puis scripts/extract.sh (watch le fait lui-même). Écran nécessaire (sous Linux sans écran : scripts/xvfb.sh).
set -euo pipefail
source "$(dirname "$0")/env.sh"
cmd=${1:-run}
ensure_extracted() { [ -f "$ROOT/app/Extracted/Extracted.fs" ] || "$ROOT/scripts/extract.sh" "${1:-lax}"; }
case $cmd in
  run)
    ensure_extracted lax
    exec dotnet run --project "$ROOT/app/HostStatic" -c Debug -p:PublishAot=false --nologo ;;
  watch)
    mode=${2:-lax}
    "$ROOT/scripts/loop.sh" "$mode"
    dotnet build "$ROOT/app/HostDev" -c Release --nologo -v quiet
    DLL="$ROOT/app/Extracted/bin/Release/net10.0/Extracted.dll"
    sig() { stat -c %Y:%s "$ROOT"/fst/*.fst | tr '\n' ' '; }
    dotnet "$ROOT/app/HostDev/bin/Release/net10.0/HostDev.dll" "$DLL" "$ROOT/logs/dev.log" & P=$!
    trap 'kill $P 2>/dev/null; exit 0' INT TERM
    echo "fenêtre lancée (pid $P) ; surveillance de fst/*.fst (mode $mode) ; Ctrl-C pour arrêter"
    last=$(sig)
    while kill -0 $P 2>/dev/null; do
      sleep 0.5; now=$(sig)
      if [ "$now" != "$last" ]; then last=$now; "$ROOT/scripts/loop.sh" "$mode" || echo "(erreur : corrigez et sauvegardez à nouveau)"; fi
    done ;;
  aot)
    ensure_extracted full
    rid=$(dotnet --info | awk '/RID:/{print $2; exit}')
    dotnet publish "$ROOT/app/HostStatic" -c Release -r "$rid" --nologo -o "$ROOT/out/aot-$rid"
    echo "NativeAOT : $ROOT/out/aot-$rid/HostStatic" ;;
  *) echo "usage : dev.sh [run | watch [lax|admit|full] | aot]" >&2; exit 2 ;;
esac
