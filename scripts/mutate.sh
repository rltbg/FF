#!/usr/bin/env bash
# Mutations volontaires du code F* : montre ce que détectent les preuves et ce que détectent les tests (en F*).
# Chaque mutation : vérification complète ; si elle passe -> tests F* (JIT) ; sinon mode --lax -> tests F*.
# Une mutation que ni F* ni les tests ne détectent est un trou de la suite : le script échoue.
set -uo pipefail
source "$(dirname "$0")/env.sh"
FILES=(Core Big App)
T=$(mktemp -d); for f in "${FILES[@]}"; do cp "$ROOT/fst/$f.fst" "$T/$f.fst"; done
restore() { for f in "${FILES[@]}"; do cp "$T/$f.fst" "$ROOT/fst/$f.fst"; done; "$ROOT/scripts/extract.sh" full >/dev/null 2>&1; rm -rf "$T"; }
trap restore EXIT
undetected=0
# 0 si les tests F* signalent un FAIL (mutation détectée). Un échec d'infrastructure (vérification des tests, extraction,
# build) n'est PAS une détection : il fait échouer le script.
infra=0
run_tests() { local out; out=$("$ROOT/scripts/ftests.sh" --no-aot 2>&1)
  if echo "$out" | grep -qE "KO|VIDE|error"; then echo "ERREUR D'INFRASTRUCTURE des tests :"; echo "$out" | head -8; infra=1; return 1; fi
  echo "$out" | grep -E "^FAIL|checks=" | head -3
  echo "$out" | grep -q "^FAIL"; }
mutate() { # nom, module, avant, après
  for f in "${FILES[@]}"; do cp "$T/$f.fst" "$ROOT/fst/$f.fst"; done
  python3 - "$ROOT/fst/$2.fst" "$3" "$4" <<'PY'
import sys
f,a,b=sys.argv[1:4]; s=open(f).read(); assert a in s, a; open(f,'w').write(s.replace(a,b,1))
PY
  echo "== $1"
  if out=$("$ROOT/scripts/extract.sh" full 2>&1); then
    echo "F* (preuves complètes) : ACCEPTÉE"
    if FT_MODE=full run_tests; then echo "=> détectée par les tests"; else echo "=> NON DÉTECTÉE"; undetected=1; fi
  else
    echo "F* (preuves complètes) : REJETÉE"; echo "$out" | grep -E "Error|Failed to prove|Expected type|got type" | head -3
    echo "=> détectée par F*"
    "$ROOT/scripts/extract.sh" lax >/dev/null 2>&1 && { echo "en --lax : extraite, tests :"; FT_MODE=lax run_tests && echo "=> détectée aussi par les tests"; }
  fi
}
mutate "M1 constante FNV (prime)"           Core "0x01000193ul" "0x01000192ul"
mutate "M2 constante FNV (offset)"          Core "0x811C9DC5ul" "0x811C9DC4ul"
mutate "M3 borne d'âge 151"                 Core "U32.lte n 150ul" "U32.lte n 151ul"
mutate "M4 règle printable (C1 -> 158)"     Core "n <= 159)" "n <= 158)"
mutate "M5 longueur de nom 21"              Core "n <= 20 &&" "n <= 21 &&"
mutate "M6 chiffre décimal décalé (Big)"    Big  "C.char_of_int (48 + n % 10)" "C.char_of_int (49 + n % 10)"
mutate "M7 modulo des lignes de texte"      Big  "string_of_int (i % 97)" "string_of_int (i % 96)"
mutate "M8 row_index sans borne"            Big  "if n < rows_count && row n = s then n else -1" "if row n = s then n else -1"
mutate "M9 Dec : borne basse -1001"         App  "if I32.gt m.counter (-1000l)" "if I32.gt m.counter (-1001l)"
mutate "M10 Select : borne <= "             App  "if U32.lt i big_rows then { m with sel" "if U32.lte i big_rows then { m with sel"
mutate "M11 digest : longueur + 1"          App  "len = U32.uint_to_t n;" "len = U32.uint_to_t (n + 1);"
mutate "M12 AddItem ne vide plus le brouillon" App "next_id = U32.add m.next_id 1ul; draft = \"\" }" "next_id = U32.add m.next_id 1ul }"
mutate "M13 Reset ne remet pas à zéro"      App  "| Reset -> { m with counter = 0l }" "| Reset -> m"
[ $infra -eq 0 ] || { echo "MUTATIONS : erreur d'infrastructure"; exit 1; }
[ $undetected -eq 0 ] && echo "MUTATIONS : toutes détectées" || { echo "MUTATIONS : au moins une non détectée"; exit 1; }
