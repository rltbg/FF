#!/usr/bin/env bash
# Balayage de TOUTE la bibliothèque standard de F* (ulib) : chaque module est extrait comme bibliothèque
# (--custard_entry_module : toutes ses définitions publiques sont des racines), puis compilé en F#.
# Classement : OK (n définitions extraites) / VIDE (rien d'exécutable : spécifications, lemmes) /
#              EXTRACT (erreur de Custard : première erreur) / BUILD (le F# généré ne compile pas) / TIMEOUT.
# usage : ulib_sweep.sh [motif]   (ex. FStar.List ; sans argument : tous) ; sortie : logs/ulib_sweep.tsv
set -uo pipefail
source "$(dirname "$0")/env.sh"
U="$TOOLS/fstar/lib/fstar/ulib"
OUT="$ROOT/logs/ulib"; rm -rf "$OUT"; mkdir -p "$OUT"
mapfile -t mods < <(ls "$U" | grep -E '\.fsti?$' | grep -vE -- '-(model|ocaml)\.|-c\.cherry|\.sketch|\.json' | sed -E 's/\.fsti?$//' | sort -u | grep -E "${1:-.}")
one() {
  local m=$1 f d="$OUT/$1"; mkdir -p "$d"; cd "$d"
  if [ -f "$U/$m.fst" ]; then f="$U/$m.fst"; else f="$U/$m.fsti"; fi
  local A=(--odir o --cache_dir c --already_cached Prims,FStar --warn_error -321)
  if ! timeout 300 fstar.exe "${A[@]}" --codegen FSharp --custard_entry_module "$m" "$f" -o "o/$m.fs" > extract.log 2>&1; then
    local rc=$?; [ $rc -eq 124 ] && { printf '%s\tTIMEOUT\t\t\n' "$m"; return; }
    local e; e=$(grep -m1 -A1 -E "^\* (Error|Warning)" extract.log | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-200)
    [ -z "$e" ] && e=$(grep -v '^$' extract.log | head -2 | tr '\n' ' ' | cut -c1-200)
    printf '%s\tEXTRACT\t\t%s\n' "$m" "$e"; return
  fi
  if [ ! -f "o/$m.fs" ]; then printf '%s\tVIDE\t0\tpas de fichier produit\n' "$m"; return; fi
  local n; n=$(grep -cE '^(let|type) ' "o/$m.fs")
  if [ "$n" -eq 0 ]; then printf '%s\tVIDE\t0\t\n' "$m"; return; fi
  if ( cd o && timeout 300 dotnet build -c Release --nologo -v quiet > ../build.log 2>&1 ); then printf '%s\tOK\t%s\t\n' "$m" "$n"
  else printf '%s\tBUILD\t%s\t%s\n' "$m" "$n" "$(grep -m1 ' error ' "$d/build.log" | sed -E 's|^.*/([^/]+\([0-9,]+\))|\1|' | cut -c1-200)"; fi
}
export -f one; export OUT U ROOT PATH DOTNET_ROOT DOTNET_CLI_TELEMETRY_OPTOUT DOTNET_NOLOGO DOTNET_SKIP_FIRST_TIME_EXPERIENCE
printf '%s\n' "${mods[@]}" | xargs -P 4 -I{} bash -c 'one {}' | sort > "$ROOT/logs/ulib_sweep.tsv"
echo "modules : ${#mods[@]}"; cut -f2 "$ROOT/logs/ulib_sweep.tsv" | sort | uniq -c | sort -rn
# copie versionnée du résultat (docs/) et couverture par la suite de tests F*
if [ -z "${1:-}" ]; then
  cp "$ROOT/logs/ulib_sweep.tsv" "$ROOT/docs/ULIB-SWEEP.tsv"
  if [ -f "$ROOT/out/ftests/fs/TMain.fs" ]; then python3 "$ROOT/scripts/coverage_ulib.py" "$ROOT" > "$ROOT/docs/COUVERTURE-ULIB.md" && sed -n 7p "$ROOT/docs/COUVERTURE-ULIB.md"; fi
fi
