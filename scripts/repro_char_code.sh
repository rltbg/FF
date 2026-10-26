#!/usr/bin/env bash
# Rejoue les cas de docs/FSTAR-char_code.md et vérifie le comportement attendu avec la version de F* installée.
# Si le cas 1 ne produit plus d'Error 395, le défaut est corrigé en amont : supprimer le contournement.
set -uo pipefail
source "$(dirname "$0")/env.sh"
W=$(mktemp -d); cd "$W"; cp "$ROOT"/docs/repro/*.fst .
A=(--odir o --cache_dir c --already_cached Prims,FStar --warn_error -321)
st=0
ext() { # module main [options F*...]
  local m=$1 mn=$2; shift 2
  fstar.exe "${A[@]}" --cache_checked_modules $m.fst >/dev/null 2>&1 || { echo "vérification KO ($m)"; return 99; }
  fstar.exe "${A[@]}" "$@" --codegen FSharp --custard_main $m.$mn $m.fst -o o/$m/$m.fs > $m.log 2>&1
}
run() { ( cd o/$1 && dotnet build -c Release --nologo -v quiet >/dev/null 2>&1 && dotnet bin/Release/net10.0/$1.dll ); }
echo "cas 1 : u32_of_char tel quel"
if ext CharCodeFails main; then echo "  => EXTRACTION RÉUSSIE : défaut corrigé en amont, contournement à retirer"; st=1
elif grep -q "Error 395" CharCodeFails.log && grep -q "FStar.Char.char_code" CharCodeFails.log; then echo "  OK Error 395 (char_code) comme documenté"
else echo "  KO erreur inattendue"; head -5 CharCodeFails.log; st=1; fi
echo "cas 2 : --custard_extern_type FStar.Char.char_code=uint32"
if ext CharCodeFails main --custard_extern_type FStar.Char.char_code=uint32; then echo "  => l'option fonctionne désormais"; st=1
elif grep -q "Error 395" CharCodeFails.log; then echo "  OK l'option ne contourne pas l'erreur, comme documenté"; else echo "  KO"; st=1; fi
echo "cas 3 : contournement B (assume val + custard_extern)"
if ext CharCodeWorkaround main; then out=$(run CharCodeWorkaround); [[ "$out" == *"7 est un chiffre"* && "$out" == *"x n'est pas un chiffre"* ]] && echo "  OK extrait, compile, s'exécute" || { echo "  KO exécution: $out"; st=1; }; else echo "  KO"; head -5 CharCodeWorkaround.log; st=1; fi
echo "cas 4 : contournement A (int_of_char)"
if ext CharCodeIntOfChar main; then out=$(run CharCodeIntOfChar); [[ "$out" == *"7 est un chiffre"* && "$out" == *"x n'est pas un chiffre"* ]] && echo "  OK extrait, compile, s'exécute" || { echo "  KO exécution: $out"; st=1; }; else echo "  KO"; st=1; fi
echo "cas 5 : 0xD7FF est-il un char_code ? (spec : n < 0xd7ff)"
printf 'module Edge\nlet x : FStar.Char.char_code = 0xD7FFul\n' > Edge.fst
if fstar.exe "${A[@]}" Edge.fst >/dev/null 2>&1; then echo "  => accepté : la borne a été corrigée en amont"; st=1; else echo "  OK rejeté (0xD7FF exclu par la spec actuelle, probable erreur d'un cran)"; fi
rm -rf "$W"; exit $st
