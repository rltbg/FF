#!/usr/bin/env bash
# Compile les projets du bureau (JIT, Release). `build.sh --aot` publie en plus HostStatic en NativeAOT (linux-x64) dans out/.
# Le NativeAOT de chaque plateforme est construit par la CI (docs/CI.md). (Les tests : scripts/ftests.sh, en F*.)
set -euo pipefail
source "$(dirname "$0")/env.sh"
[ -f "$ROOT/app/Extracted/Extracted.fs" ] || "$ROOT/scripts/extract.sh" full   # F# extrait non versionné
cd "$ROOT/app"
for p in HostStatic HostDev; do dotnet build $p -c Release --nologo -v quiet; done
[ "${1:-}" = --aot ] || exit 0
for p in HostStatic; do
  dotnet publish $p -c Release -r linux-x64 --nologo -o "$ROOT/out/$p" 2>&1 | grep -E "warning|error|->" || true
done
