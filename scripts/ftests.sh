#!/usr/bin/env bash
# Suite de tests ENTIÈREMENT en F* (ftests/*.fst) : vérification, extraction Custard (--custard_main TMain.main),
# exécution JIT puis NativeAOT. Aucun test n'est écrit en F#.
# Garde-fou : Custard évalue les termes clos ; un `check` dont l'argument est devenu `true` ne teste plus rien (VIDE).
# usage : ftests.sh [--no-aot]      FT_MODE=full|admit|lax (défaut full ; lax sert aux mutations qui cassent une preuve)
set -euo pipefail
source "$(dirname "$0")/env.sh"
O="$ROOT/out/ftests"; rm -rf "$O/fs" "$O/aot"; mkdir -p "$O/fs"
# fichiers de test générés (F* commité ; régénérés ici pour qu'ils ne divergent jamais de leur table)
python3 "$ROOT/scripts/gen_tmachine.py" "$ROOT/.tools/src/FStar/ulib" > "$ROOT/ftests/TMachine.fst" 2> /dev/null || { echo "gen_tmachine.py KO"; exit 1; }
python3 "$ROOT/scripts/gen_tulib.py" "$ROOT/ftests/ulib_cases.py" > "$ROOT/ftests/TUlib.fst" 2> /dev/null || { echo "gen_tulib.py KO"; exit 1; }
fstar_mode "${FT_MODE:-full}"
cd "$ROOT/fst"
for m in "${FST_MODULES[@]}"; do fstar.exe "${FA[@]}" --cache_checked_modules $m.fst > /dev/null 2>&1 || { echo "VERIF KO: $m (cœur)"; exit 1; }; done
cd "$ROOT/ftests"
TA=("${FA[@]}" --warn_error -272 --include "$ROOT/fst" --include .)
# Chaque module est vérifié comme racine, dans l'ordre des dépendances (ftests/ORDER) : seule une racine voit son
# .checked écrit ; vérifier TMain seul re-vérifierait ses dépendances en mémoire sans les mettre en cache.
for m in $(cat ORDER) TMain; do
  fstar.exe "${TA[@]}" --cache_checked_modules $m.fst > "$O/verif_$m.log" 2>&1 || { echo "VERIF KO: $m"; grep -v "^$" "$O/verif_$m.log" | head -40; exit 1; }
done
echo "vérifié : $(cat ORDER) TMain"
fstar.exe "${TA[@]}" --cache_checked_modules --codegen FSharp --custard_main TMain.main TMain.fst -o "$O/fs/TMain.fs" > "$O/extract.log" 2>&1 || { echo "EXTRACT KO"; head -30 "$O/extract.log"; exit 1; }
if grep -qE "_check \(*\"[^\"]*\"\)* \(*true\)*[ )]|_check \(*\"[^\"]*\"\)* \(*true\)*$" "$O/fs/TMain.fs"; then
  echo "VIDE : un check est devenu 'true' à l'extraction (terme clos évalué par Custard) :"
  grep -nE "_check \(*\"[^\"]*\"\)* \(*true\)*[ )]|_check \(*\"[^\"]*\"\)* \(*true\)*$" "$O/fs/TMain.fs" | head; exit 1
fi
echo "extrait : $(wc -l < "$O/fs/TMain.fs") lignes F# générées, $(grep -c '_check' "$O/fs/TMain.fs") appels de check"
(cd "$O/fs" && dotnet build -c Release --nologo -v quiet -p:OtherFlags=--reflectionfree 2>&1 | grep -E "error|warning" | head -20) || true
run_and_check() { # exécutable : sortie conservée, bloc IO comparé à ftests/IO.expected
  local rc=0; "$@" > "$O/run.out" 2>&1 || rc=$?
  grep -vE "^(IO-BEGIN|IO-END)$" "$O/run.out" | grep -vE '^(chaîne|0x|[0-9a-f]+$)' || true
  sed -n '/^IO-BEGIN$/,/^IO-END$/p' "$O/run.out" > "$O/io.actual"
  if diff -u "$ROOT/ftests/IO.expected" "$O/io.actual" > "$O/io.diff"; then echo "IO : sortie conforme à ftests/IO.expected ($(wc -l < "$O/io.actual") lignes)"
  else echo "IO : ÉCART avec ftests/IO.expected :"; cat "$O/io.diff" | head -40; rc=1; fi
  return $rc; }
echo "== JIT"; run_and_check dotnet "$O/fs/bin/Release/net10.0/TMain.dll"
if [ "${1:-}" != "--no-aot" ]; then
  (cd "$O/fs" && dotnet publish -c Release -r linux-x64 --nologo -p:PublishAot=true -p:OtherFlags=--reflectionfree -o "$O/aot" 2>&1 | grep -E "error|warning IL|->" | head -10) || true
  echo "== AOT"; run_and_check "$O/aot/TMain"
fi
# couverture des réalisations Custard (supported_realizations) par le F# généré de la suite
python3 "$ROOT/scripts/coverage_realizations.py" "$ROOT/.tools/src/FStar/src/custard/FStarC.Custard.PrintFSharp.fst" "$O/fs/TMain.fs" > "$ROOT/docs/COUVERTURE-REALISATIONS.md" \
  && echo "couverture des réalisations : $(sed -n 3p "$ROOT/docs/COUVERTURE-REALISATIONS.md")" \
  || { echo "couverture : réalisation non exercée et non déclarée bloquée :"; grep "NON EXERC" "$ROOT/docs/COUVERTURE-REALISATIONS.md"; exit 1; }
