#!/usr/bin/env bash
# Lignes utiles (ni vides, ni commentaires seuls) par catégorie : part de F* dans le code livré et dans les tests.
source "$(dirname "$0")/env.sh"; cd "$ROOT"
useful_fs() { # F# : ni vide, ni // seul
  cat "$@" | grep -vE '^[[:space:]]*(//.*)?$' | wc -l; }
useful_fst() { # F* : ni vide, ni ligne commençant un commentaire (* ... *) sur une seule ligne, ni ligne de suite de commentaire
  cat "$@" | awk 'BEGIN{c=0} { l=$0; gsub(/^[ \t]+|[ \t]+$/,"",l); if (l=="") next;
      if (c>0) { if (l ~ /\*\)[ \t]*$/) c=0; next }
      if (l ~ /^\(\*/) { if (l !~ /\*\)[ \t]*$/) c=1; next }
      n++ } END{print n+0}'; }
cnt() { printf '%-58s %6d\n' "$1" "$2"; }
echo "== Code livré (écrit à la main)"
core=$(useful_fst fst/Core.fst fst/Big.fst fst/App.fst)
cnt "F* : Core + Big + App (logique, preuves, vue, données)" "$core"
cnt "  dont Core.fst" "$(useful_fst fst/Core.fst)"; cnt "  dont Big.fst" "$(useful_fst fst/Big.fst)"; cnt "  dont App.fst" "$(useful_fst fst/App.fst)"
ui=$(useful_fs app/Ui/*.fs); hs=$(useful_fs app/HostStatic/*.fs); hd=$(useful_fs app/HostDev/*.fs)
cnt "F# à la main : Ui (interpréteur Avalonia, boucle MVU)" "$ui"
cnt "F# à la main : HostStatic (point d'entrée JIT/AOT)" "$hs"
cnt "F# à la main : HostDev (rechargement à chaud, dev seulement)" "$hd"
liv=$((ui + hs)); cnt "F# à la main livré (Ui + HostStatic)" "$liv"
awk -v f="$core" -v s="$liv" 'BEGIN{printf "%-58s %5.0f %%\n", "Part de F* dans le code livré écrit à la main", 100*f/(f+s)}'
echo "== F# généré (non écrit à la main)"
cnt "Extracted.fs (F* extrait)" "$(useful_fs app/Extracted/Extracted.fs)"; cnt "FStarCustard.fs (bibliothèque de support générée)" "$(useful_fs app/Extracted/FStarCustard.fs)"
echo "== Tests"
cnt "F* écrit à la main : ftests/*.fst hors générés" "$(useful_fst $(ls ftests/*.fst | grep -vE 'TMachine\.fst|TUlib\.fst'))"
cnt "F* généré : TMachine.fst + TUlib.fst" "$(useful_fst ftests/TMachine.fst ftests/TUlib.fst)"
cnt "F* des cas matrice (docs/matrix/*.fst)" "$(useful_fst docs/matrix/*.fst)"
cnt "Python (générateurs de texte F*, mesure de couverture)" "$(cat scripts/gen_tmachine.py scripts/gen_tulib.py scripts/coverage_*.py ftests/ulib_cases.py | grep -vE '^[[:space:]]*(#.*)?$' | wc -l)"
cnt "Tests écrits en F#" "$(find . -path ./.tools -prune -o -path ./out -prune -o -path ./logs -prune -o -name '*.fs' -print 2>/dev/null | grep -iE 'test' | grep -v Extracted | xargs -r cat | wc -l)"
