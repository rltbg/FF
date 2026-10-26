#!/usr/bin/env bash
# Scénarios de rechargement à chaud (HostDev, AssemblyLoadContext) avec oracles sur les textes affichés.
#  A : texte de vue modifié (état conservé)    B : logique de update modifiée (Reset -> 10)
#  C : type du modèle modifié (état réinitialisé)    D : texte de vue en mode --lax
# Restaure fst/App.fst et l'extraction à la fin.
set -uo pipefail
source "$(dirname "$0")/env.sh"; source "$(dirname "$0")/xvfb.sh"
S="$ROOT/shots/hotreload"; mkdir -p "$S"; rm -f "$S"/*.png
LOG="$S/dev.log"; : > "$LOG"
cp "$ROOT/fst/App.fst" "$S/App.fst.bak"
restore() { cp "$S/App.fst.bak" "$ROOT/fst/App.fst"; rm -f "$S/App.fst.bak"; "$ROOT/scripts/extract.sh" full >/dev/null; dotnet build "$ROOT/app/Extracted" -c Release --nologo -v quiet >/dev/null; }
trap restore EXIT
"$ROOT/scripts/loop.sh" full >/dev/null
DLL="$ROOT/app/Extracted/bin/Release/net10.0/Extracted.dll"
dotnet "$ROOT/app/HostDev/bin/Release/net10.0/HostDev.dll" "$DLL" "$LOG" > "$S/app.out" 2>&1 & P=$!
waitwin; sleep 1.5
fail=0
c() { xdotool mousemove $1 $2 click 1; sleep 0.4; }
expect() { sleep 0.3; local last; last=$(grep " render " "$LOG" | tail -1)
  if [[ "$last" == *"$2"* ]]; then echo "OK [$1] « $2 »"; else echo "KO [$1] attendu « $2 », obtenu : ${last:14:120}"; fail=1; fi; }
edit() { python3 - "$ROOT/fst/App.fst" "$1" "$2" <<'PY'
import sys
f,a,b=sys.argv[1:4]; s=open(f).read(); assert a in s, a; open(f,'w').write(s.replace(a,b,1))
PY
}
cycle() { # étiquette mode : chronomètre sauvegarde -> rendu rechargé
  local n0; n0=$(grep -c "reloaded" "$LOG")
  local t0; t0=$(date +%s%3N)
  local line; line=$("$ROOT/scripts/loop.sh" $2) || { echo "KO [$1] boucle: $line"; fail=1; return; }
  for _ in $(seq 1 100); do [ "$(grep -c reloaded "$LOG")" -gt "$n0" ] && break; sleep 0.05; done
  local rl; rl=$(grep reloaded "$LOG" | tail -1)
  echo "[$1] $line | sauvegarde->rendu_ms=$(( ${rl%% *} - t0 )) | ${rl#* }"; }
c 76 139; c 76 139; c 76 139; expect état "Valeur : 3"
edit '"Valeur : "' '"Valeur HOT : "'; cycle A full; expect A "Valeur HOT : 3"; import -window root "$S/A.png"
edit '| Reset -> { m with counter = 0l }' '| Reset -> { m with counter = 10l }'; cycle B full; c 126 139; expect B "Valeur HOT : 10"; import -window root "$S/B.png"
edit '  status: form_status;
}' '  status: form_status;
  note: string;
}'
edit 'status = Editing }' 'status = Editing; note = "" }'; cycle C full; expect C "Valeur HOT : 0"; import -window root "$S/C.png"
grep -q "model-RESET" "$LOG" && echo "OK [C] modèle réinitialisé : $(grep -o 'model-RESET ([^)]*)' "$LOG" | tail -1)" || { echo "KO [C] pas de RESET"; fail=1; }
c 76 139; edit '"Valeur HOT : "' '"Valeur LAX : "'; cycle D lax; expect D "Valeur LAX : 1"; import -window root "$S/D.png"
sleep 2.5; echo "après D, sans interaction : $(grep alc-alive "$LOG" | tail -1 | cut -d' ' -f2-)"
xdotool mousemove 400 450 click 1; sleep 0.3; xdotool mousemove 450 500; sleep 4.5
echo "déchargement ALC : $(grep alc-alive "$LOG" | tail -1 | cut -d' ' -f2-) (vivants/remplacés après GC)"
echo "RSS HostDev : $(awk '/VmRSS/{print $2}' /proc/$P/status) Ko"
# non-régression : après 3 rechargements tous les contextes remplacés doivent être déchargés
# (Avalonia 12.1.4 retenait la 1re racine du ScrollViewer ; voir Ui/Runner.fs)
last=$(grep alc-alive "$LOG" | tail -1)
alive=$(echo "$last" | sed -n 's/.* \([0-9]*\)\/[0-9]* vivants=.*/\1/p')
if [ "$alive" = "0" ]; then echo "OK déchargement : 0 ancien contexte vivant (${last#* })"; else echo "KO déchargement : ${last#* }"; fail=1; fi
kill $P; wait $P 2>/dev/null
[ $fail -eq 0 ] && echo "HOTRELOAD OK" || { echo "HOTRELOAD KO"; exit 1; }
