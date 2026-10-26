#!/usr/bin/env bash
# Compile tous les projets (JIT, Release) et publie HostStatic et Tests en NativeAOT dans out/.
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT/app"
for p in HostStatic HostDev Tests; do dotnet build $p -c Release --nologo -v quiet; done
for p in HostStatic Tests; do
  dotnet publish $p -c Release -r linux-x64 --nologo -o "$ROOT/out/$p" 2>&1 | grep -E "warning|error|->" || true
done
