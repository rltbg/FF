#!/usr/bin/env bash
# Un tour de boucle chronométré : vérification F* -> extraction -> compilation de Extracted.dll.
# usage : loop.sh [full|admit|lax]
set -euo pipefail
source "$(dirname "$0")/env.sh"
MODE=${1:-full}; fstar_mode $MODE
L="$ROOT/logs/loop"; mkdir -p "$L"
now() { date +%s%N; }
t0=$(now)
cd "$ROOT/fst"
for m in "${FST_MODULES[@]}"; do fstar.exe "${FA[@]}" --cache_checked_modules $m.fst >> "$L/check.log" 2>&1 || { echo "VÉRIFICATION KO"; tail -20 "$L/check.log"; exit 1; }; done
t1=$(now)
out=$(mktemp -d)
fstar.exe "${FA[@]}" --codegen FSharp $(for m in "${FST_MODULES[@]}"; do printf -- '--custard_entry_module %s ' $m; done) App.fst -o "$out/Extracted.fs" >> "$L/extract.log" 2>&1 || { echo "EXTRACTION KO"; tail -20 "$L/extract.log"; exit 1; }
cp "$out"/Extracted.fs "$out"/FStarCustard.fs "$out"/Extracted.fsproj "$ROOT/app/Extracted/"; rm -rf "$out"
t2=$(now)
dotnet build "$ROOT/app/Extracted" -c Release --nologo > "$L/build.log" 2>&1 || { echo "COMPILATION KO"; grep -E "error" "$L/build.log" | head; exit 1; }
t3=$(now)
ms() { echo $(( ($2 - $1) / 1000000 )); }
echo "mode=$MODE verif_ms=$(ms $t0 $t1) extraction_ms=$(ms $t1 $t2) build_ms=$(ms $t2 $t3) total_ms=$(ms $t0 $t3)"
