#!/usr/bin/env bash
# Test de fumée GUI (Xvfb) : pilote les 3 onglets par xdotool et vérifie l'état du modèle après chaque
# étape (journal MVU_TRACE écrit par HostStatic), la vie du processus et la propriété de la fenêtre.
# Frappe rapide suivie d'un clic immédiat : exerce la course frappe/rendu/clic.
# usage : ui_smoke.sh <cmd...>
set -uo pipefail
source "$(dirname "$0")/env.sh"; source "$(dirname "$0")/xvfb.sh"
S="$ROOT/shots/smoke"; mkdir -p "$S"; rm -f "$S"/*.png
export MVU_TRACE="$S/trace.log"; : > "$MVU_TRACE"
"$@" > "$S/app.log" 2>&1 & P=$!
waitwin || { echo "KO: pas de fenêtre"; cat "$S/app.log"; kill $P; exit 1; }
sleep 1.5
fail=0
c() { xdotool mousemove $1 $2 click 1; sleep ${3:-0.4}; }
shot() { import -window root "$S/$1.png"; convert "$S/$1.png" -crop 540x330+0+0 +repage "$S/$1.png"; }
expect() { # étiquette, motif attendu dans la dernière ligne du journal
  sleep 0.3
  if ! kill -0 $P 2>/dev/null; then echo "KO [$1] processus mort"; head -20 "$S/app.log"; fail=1; return; fi
  local last; last=$(tail -1 "$MVU_TRACE")
  if [[ "$last" == *"$2"* ]]; then echo "OK [$1] $2"; else echo "KO [$1] attendu « $2 », obtenu : $last"; fail=1; fi; }
wpid=$(xprop -id "$(win)" _NET_WM_PID | awk '{print $3}')
[ "$wpid" = "$P" ] && echo "OK fenêtre _NET_WM_PID=$wpid = PID $P" || { echo "KO _NET_WM_PID=$wpid PID=$P"; fail=1; }
shot 0_init
c 76 139; c 76 139; c 76 139; c 40 139; expect compteur "counter=2"; shot 1_compteur
c 160 41; expect onglet "tab=items"
c 130 115; xdotool type --delay 10 "pommes"; c 286 115 0
c 130 115; xdotool type --delay 10 "poires"; c 286 115 0
c 130 115; xdotool type --delay 10 "xxxxxxxxxxxxxxxxxxxxxxxxx"; c 286 115
expect liste "items=poires[ ],pommes[ ] draft=xxxxxxxxxxxxxxxxxxxxxxxxx name="
c 36 155; expect cocher "items=poires[x],pommes[ ]"
c 100 235; expect supprimer "items=pommes[ ] "; shot 2_liste
c 237 41; c 270 115; xdotool type --delay 10 "Ada Lovelace"; c 270 155 0; xdotool type --delay 10 "36"; c 60 193
expect accepte "status=accepted:Ada Lovelace,36,4267605246"; shot 3_accepte
c 270 155; xdotool key ctrl+a; xdotool type --delay 10 "200"; c 60 193
expect rejete "age=200 status=rejected:âge : entier décimal entre 0 et 150"; shot 4_rejete
echo "rendus journalisés : $(wc -l < "$MVU_TRACE") ; RSS : $(awk '/VmRSS/{print $2}' /proc/$P/status) Ko"
kill $P 2>/dev/null; wait $P 2>/dev/null
[ $fail -eq 0 ] && echo "SMOKE OK" || { echo "SMOKE KO"; exit 1; }
