#!/usr/bin/env bash
# Boucle de dev chronométrée sur de vraies éditions : 3 éditions de vue (App.fst) et 3 éditions de
# Core.fst (qui revérifient App) par mode F*. Restaure les sources à la fin.
set -uo pipefail
source "$(dirname "$0")/env.sh"
cp "$ROOT/fst/App.fst" /tmp/App.fst.bak; cp "$ROOT/fst/Core.fst" /tmp/Core.fst.bak
restore() { cp /tmp/App.fst.bak "$ROOT/fst/App.fst"; cp /tmp/Core.fst.bak "$ROOT/fst/Core.fst"; "$ROOT/scripts/extract.sh" full >/dev/null; }
trap restore EXIT
for mode in full admit lax; do "$ROOT/scripts/loop.sh" $mode >/dev/null; done   # caches chauds
for mode in full admit lax; do
  for i in 1 2 3; do
    sed -i "s/VHeading \"Compteur\"/VHeading \"Compteur$i$mode\"/; s/VHeading \"Compteur[0-9a-z]*\"/VHeading \"Compteur$i$mode\"/" "$ROOT/fst/App.fst"
    echo "vue  $("$ROOT/scripts/loop.sh" $mode)"
  done
  for i in 1 2 3; do
    sed -i "s/^let age_ok (n:U32.t) : bool = U32.lte n 150ul.*/let age_ok (n:U32.t) : bool = U32.lte n 150ul (* $i$mode *)/" "$ROOT/fst/Core.fst"
    echo "core $("$ROOT/scripts/loop.sh" $mode)"
  done
done
