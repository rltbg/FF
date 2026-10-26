#!/usr/bin/env bash
# Mutations volontaires du code F* : montre ce que détectent les preuves et ce que détectent les tests.
#  M1 constante FNV (prime 0x01000193 -> 0x01000192) : aucune preuve ne fixe la constante
#  M2 borne d'âge 150 -> 151 : contredit le type de parse_age (n <= 150)
#  M3 règle printable (C1 jusqu'à 159 -> 158) : aucune preuve ne fixe la règle
# Chaque mutation : vérification complète ; si elle passe -> tests ; sinon mode --lax -> tests.
set -uo pipefail
source "$(dirname "$0")/env.sh"
cp "$ROOT/fst/Core.fst" /tmp/Core.fst.orig
restore() { cp /tmp/Core.fst.orig "$ROOT/fst/Core.fst"; "$ROOT/scripts/extract.sh" full >/dev/null; dotnet build "$ROOT/app/Tests" -c Release --nologo -v quiet >/dev/null; }
trap restore EXIT
undetected=0
# renvoie 0 si les tests échouent (mutation détectée)
run_tests() { dotnet build "$ROOT/app/Tests" -c Release --nologo -v quiet >/dev/null || return 0
  local out; out=$(dotnet "$ROOT/app/Tests/bin/Release/net10.0/Tests.dll"); local rc=$?; echo "$out" | tail -3
  [ $rc -ne 0 ]; }
mutate() { # nom, avant, après
  cp /tmp/Core.fst.orig "$ROOT/fst/Core.fst"
  python3 - "$ROOT/fst/Core.fst" "$2" "$3" <<'PY'
import sys
f,a,b=sys.argv[1:4]; s=open(f).read(); assert a in s, a; open(f,'w').write(s.replace(a,b,1))
PY
  echo "== $1"
  if out=$("$ROOT/scripts/extract.sh" full 2>&1); then
    echo "F* (preuves complètes) : ACCEPTÉE"
    if run_tests; then echo "=> détectée par les tests"; else echo "=> NON DÉTECTÉE"; undetected=1; fi
  else
    echo "F* (preuves complètes) : REJETÉE"; echo "$out" | grep -E "Error|Failed to prove|Expected type|got type" | head -4
    echo "=> détectée par F*"
    "$ROOT/scripts/extract.sh" lax >/dev/null 2>&1 && { echo "en --lax : extraite, tests :"; run_tests && echo "=> détectée aussi par les tests"; }
  fi
}
mutate "M1 constante FNV" "0x01000193ul" "0x01000192ul"
mutate "M2 borne d'âge 151" "U32.lte n 150ul" "U32.lte n 151ul"
mutate "M3 règle printable" "n <= 159)" "n <= 158)"
[ $undetected -eq 0 ] && echo "MUTATIONS : toutes détectées" || { echo "MUTATIONS : au moins une non détectée"; exit 1; }
