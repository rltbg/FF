#!/usr/bin/env bash
# Vérifie les modules F* dans l'ordre des dépendances puis extrait vers app/Extracted/.
# usage : extract.sh [full|admit|lax]
set -euo pipefail
source "$(dirname "$0")/env.sh"
fstar_mode "${1:-full}"
cd "$ROOT/fst"
for m in Core App; do fstar.exe "${FA[@]}" --cache_checked_modules $m.fst; done
out=$(mktemp -d)
fstar.exe "${FA[@]}" --codegen FSharp --custard_entry_module Core --custard_entry_module App App.fst -o "$out/Extracted.fs"
mkdir -p "$ROOT/app/Extracted"
cp "$out"/Extracted.fs "$out"/FStarCustard.fs "$out"/Extracted.fsproj "$ROOT/app/Extracted/"
rm -rf "$out"
