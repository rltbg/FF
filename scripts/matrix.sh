#!/usr/bin/env bash
# Matrice d'extraction F* -> F# : chaque docs/matrix/Mx*.fst est vérifié, extrait, compilé puis exécuté (doit afficher OK).
# Classement par étape d'échec : VERIF (notre F*), EXTRACT (Custard), BUILD (compilation F#), RUN (exécution).
# usage : matrix.sh [Mx01 Mx05 ...]   (sans argument : tous) ; sortie : logs/matrix.tsv
set -uo pipefail
source "$(dirname "$0")/env.sh"
OUT="$ROOT/logs/matrix"; rm -rf "$OUT"; mkdir -p "$OUT"
one() {
  local f=$1 m; m=$(basename "$f" .fst); local d="$OUT/$m"; mkdir -p "$d"; cd "$d"; cp "$f" .
  cp "$ROOT"/docs/matrix/MxUtil.fst .
  local A=(--odir o --cache_dir c --already_cached Prims,FStar --warn_error -321)
  fstar.exe "${A[@]}" --cache_checked_modules MxUtil.fst > util.log 2>&1 || { printf '%s\tVERIF\tMxUtil: %s\n' "$m" "$(grep -m1 -A2 Error util.log | tr '\n' ' ')"; return; }
  local st detail=""
  if ! fstar.exe "${A[@]}" --cache_checked_modules $m.fst > verif.log 2>&1; then st=VERIF; detail=$(grep -m1 -A2 "Error" verif.log | tr '\n' ' ' | cut -c1-230)
  elif ! fstar.exe "${A[@]}" --codegen FSharp --custard_main $m.main $m.fst -o o/$m/$m.fs > extract.log 2>&1; then st=EXTRACT; detail=$(grep -m1 -A2 "Error" extract.log | tr '\n' ' ' | cut -c1-230)
  elif ! ( cd o/$m && dotnet build -c Release --nologo -v quiet > ../../build.log 2>&1 ); then st=BUILD; detail=$(grep -m1 "error" build.log | sed 's|.*/||' | cut -c1-230)
  else
    local out; out=$(cd o/$m && dotnet bin/Release/net10.0/$m.dll 2>&1)
    if [[ "$out" == *OK* && "$out" != *FAIL* ]]; then
      # garde-fou : Custard évalue les termes clos ; un check dont l'argument est devenu `true` ne teste plus rien
      if grep -qE "_check \(*true\)*[ )]|_check \(*true\)*$" o/$m/$m.fs; then st=VIDE; detail="un check est devenu 'true' à l'extraction (terme clos évalué)"; else st=OK; fi
    else st=RUN; detail=$(echo "$out" | head -2 | tr '\n' ' ' | cut -c1-230); fi
  fi
  printf '%s\t%s\t%s\n' "$m" "$st" "$detail"
}
export -f one; export OUT ROOT PATH DOTNET_ROOT DOTNET_CLI_TELEMETRY_OPTOUT DOTNET_NOLOGO DOTNET_SKIP_FIRST_TIME_EXPERIENCE
if [ $# -gt 0 ]; then files=(); for p in "$@"; do files+=("$ROOT"/docs/matrix/$p*.fst); done; else files=("$ROOT"/docs/matrix/Mx[0-9]*.fst); fi
printf '%s\n' "${files[@]}" | xargs -P 4 -I{} bash -c 'one {}' | sort > "$ROOT/logs/matrix.tsv"
awk -F"\t" "{printf \"%-18s %-8s %s\\n\", \$1, \$2, substr(\$3,1,200)}" "$ROOT/logs/matrix.tsv"
echo; echo "résumé : $(cut -f2 "$ROOT/logs/matrix.tsv" | sort | uniq -c | tr '\n' ' ')"
# comparaison avec les résultats attendus (les défauts connus de F* y figurent : EXTRACT/RUN)
if [ $# -eq 0 ]; then
  if diff <(cut -f1,2 "$ROOT/logs/matrix.tsv") "$ROOT/docs/matrix/EXPECTED.tsv" > "$OUT/diff.txt"; then echo "conforme à docs/matrix/EXPECTED.tsv"
  else echo "ÉCART avec docs/matrix/EXPECTED.tsv (un défaut a changé de statut ? voir docs/UPSTREAM-FSTAR.md) :"; cat "$OUT/diff.txt"; exit 1; fi
fi
