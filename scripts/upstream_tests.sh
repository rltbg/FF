#!/usr/bin/env bash
# Tests F* AMONT exécutés via le backend F# (aucun F# à la main) :
#  - tests/machine_integers/Test*.fst (entiers machine : comparaisons, conversions, caractères, impressions, rotations, décalages) ;
#  - la branche F# de tests/custard (FS_TESTS du Makefile amont : 28 programmes dont BytesFS, Wide128, Rotate, MachineInts...).
# Étapes : VERIF (F*), EXTRACT (Custard), BUILD (F#), RUN (exécution, code retour 0). Sortie : logs/upstream.tsv.
# Les sources viennent de scripts/sources.sh (.tools/src/FStar) à la même version que le compilateur.
# usage : upstream_tests.sh [nom ...]
set -uo pipefail
source "$(dirname "$0")/env.sh"
SRC="$ROOT/.tools/src/FStar/tests"
[ -d "$SRC/custard" ] || { echo "sources absentes : lancer scripts/sources.sh"; exit 2; }
OUT="$ROOT/logs/upstream"; rm -rf "$OUT"; mkdir -p "$OUT"
one() { # suite nom
  local suite=$1 name=$2 dir; dir="$OUT/$suite.$name"; mkdir -p "$dir"; cd "$dir"
  local srcdir="$SRC/$suite" flags="" main="--custard_main $name.main"
  if [ "$suite" = machine_integers ]; then main="--custard_main $name"; fi
  flags=$(sed -n "s/^FLAGS_$name *= *//p" "$SRC/custard/Makefile" | head -1)
  [ "$suite" = machine_integers ] && flags="--warn_error -272"
  local A=(--odir o --cache_dir c --already_cached Prims,FStar --warn_error -321 --include "$srcdir" $flags)
  local st detail="" dep
  # dépendances locales du test (modules de tests/<suite>/ à vérifier d'abord, comme racines, pour écrire leur .checked)
  for dep in $(sed -n "s/^DEPS_$name *= *//p" "$ROOT/scripts/upstream_deps.txt"); do
    fstar.exe "${A[@]}" --cache_checked_modules "$srcdir/$dep.fst" > verif_dep.log 2>&1 || true
  done
  if ! fstar.exe "${A[@]}" --cache_checked_modules "$srcdir/$name.fst" > verif.log 2>&1; then st=VERIF; detail=$(grep -m1 -A2 "Error" verif.log | tr '\n' ' ' | cut -c1-200)
  elif ! fstar.exe "${A[@]}" --codegen FSharp $main "$srcdir/$name.fst" -o "o/$name.fs" > extract.log 2>&1; then st=EXTRACT; detail=$(grep -m1 -A2 "Error" extract.log | tr '\n' ' ' | cut -c1-200)
  elif { [ "$suite" = machine_integers ] && sed -i 's|<OutputType>Library</OutputType>|<OutputType>Exe</OutputType>|' o/$name.fsproj; false; }; then :
  elif ! ( cd o && dotnet build -c Release --nologo -v quiet > ../build.log 2>&1 ); then st=BUILD; detail=$(grep -m1 "error" build.log | sed 's|.*/||' | cut -c1-200)
  else
    local rc; ( cd o && dotnet bin/Release/net10.0/$name.dll > ../run.out 2>&1 ); rc=$?
    if [ $rc -eq 0 ]; then st=OK; else st=RUN; detail="code $rc : $(head -2 run.out | tr '\n' ' ' | cut -c1-160)"; fi
  fi
  printf '%s.%s\t%s\t%s\n' "$suite" "$name" "$st" "$detail"
}
export -f one; export OUT ROOT SRC PATH DOTNET_ROOT DOTNET_CLI_TELEMETRY_OPTOUT DOTNET_NOLOGO DOTNET_SKIP_FIRST_TIME_EXPERIENCE
# la sortie F# de tests/custard est « o/<Nom>/<Nom>.fs » côté amont ; ici o/<Nom>.fs + projet généré à côté
list() {
  if [ $# -gt 0 ]; then for n in "$@"; do if [ -f "$SRC/machine_integers/$n.fst" ]; then echo "machine_integers $n"; else echo "custard $n"; fi; done; return; fi
  for f in "$SRC"/machine_integers/Test*.fst; do echo "machine_integers $(basename "$f" .fst)"; done
  grep -E "^FS_TESTS *\+?=" "$SRC/custard/Makefile" | sed 's/^FS_TESTS *+\?= *//' | tr ' ' '\n' | grep -v '^$' | sort -u | while read -r n; do echo "custard $n"; done
}
list "$@" | xargs -P 4 -L1 bash -c 'one "$0" "$1"' | sort > "$ROOT/logs/upstream.tsv"
awk -F"\t" '{printf "%-34s %-8s %s\n", $1, $2, substr($3,1,170)}' "$ROOT/logs/upstream.tsv"
echo; echo "résumé : $(cut -f2 "$ROOT/logs/upstream.tsv" | sort | uniq -c | tr '\n' ' ')"
# comparaison avec les résultats attendus (les défauts connus de F* y figurent : EXTRACT) ; seulement pour la passe complète
if [ $# -eq 0 ]; then
  if diff <(cut -f1,2 "$ROOT/logs/upstream.tsv") "$ROOT/docs/upstream/EXPECTED.tsv" > "$OUT/diff.txt"; then echo "conforme à docs/upstream/EXPECTED.tsv"
  else echo "ÉCART avec docs/upstream/EXPECTED.tsv :"; cat "$OUT/diff.txt"; exit 1; fi
fi
