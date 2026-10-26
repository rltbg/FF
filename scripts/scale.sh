#!/usr/bin/env bash
# Passage à l'échelle des modèles F* extraits (Seq = liste F#, Map et Set = chaînes de fermetures, RBMap = arbre rouge-noir).
# Pour chaque structure et chaque N : temps d'exécution, plantage éventuel (dépassement de pile). Sortie : logs/scale.tsv
set -uo pipefail
source "$(dirname "$0")/env.sh"
OUT="$ROOT/logs/scale"; rm -rf "$OUT"; mkdir -p "$OUT"; : > "$ROOT/logs/scale.tsv"
Ns=${*:-"1000 10000 100000"}
for tpl in "$ROOT"/docs/scale/Sc_*.fst.in; do
  base=$(basename "$tpl" .fst.in)
  for n in $Ns; do
    d="$OUT/${base}_$n"; mkdir -p "$d"; cd "$d"
    sed "s/@N@/$n/" "$tpl" > $base.fst; cp "$ROOT/docs/matrix/MxUtil.fst" .
    A=(--odir o --cache_dir c --already_cached Prims,FStar --warn_error -321)
    fstar.exe "${A[@]}" --cache_checked_modules MxUtil.fst >/dev/null 2>&1
    if ! fstar.exe "${A[@]}" --cache_checked_modules $base.fst > verif.log 2>&1; then printf '%s\t%s\tVERIF\t%s\n' "$base" "$n" "$(grep -m1 -A2 Error verif.log | tr '\n' ' ' | cut -c1-160)" >> "$ROOT/logs/scale.tsv"; continue; fi
    fstar.exe "${A[@]}" --codegen FSharp --custard_main $base.main $base.fst -o o/$base/$base.fs > extract.log 2>&1 || { printf '%s\t%s\tEXTRACT\t%s\n' "$base" "$n" "$(grep -m1 -A2 Error extract.log | tr '\n' ' ' | cut -c1-160)" >> "$ROOT/logs/scale.tsv"; continue; }
    ( cd o/$base && dotnet build -c Release --nologo -v quiet > ../../build.log 2>&1 ) || { printf '%s\t%s\tBUILD\t\n' "$base" "$n" >> "$ROOT/logs/scale.tsv"; continue; }
    s=$(date +%s%N); out=$(cd o/$base && timeout 120 dotnet bin/Release/net10.0/$base.dll 2>&1); rc=$?; e=$(date +%s%N)
    ms=$(( (e - s) / 1000000 ))
    if [ $rc -eq 0 ] && [[ "$out" == *OK* ]]; then st=OK; elif [ $rc -eq 124 ]; then st=TIMEOUT; elif [ $rc -ge 128 ]; then st="CRASH(rc=$rc)"; else st="KO(rc=$rc)"; fi
    printf '%s\t%s\t%s\t%s ms\n' "$base" "$n" "$st" "$ms" >> "$ROOT/logs/scale.tsv"
  done
done
awk -F'\t' '{printf "%-12s N=%-8s %-14s %s\n", $1, $2, $3, $4}' "$ROOT/logs/scale.tsv"
