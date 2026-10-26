#!/usr/bin/env bash
# Limite de la liste NON virtualisée (onglet Liste : un contrôle par élément) : temps de rendu pour N éléments.
# usage : list_scale.sh <cmd...>   (N dans LIST_NS, défaut "100 500 1000 2000 5000")
set -uo pipefail
source "$(dirname "$0")/env.sh"; source "$(dirname "$0")/xvfb.sh"
T="$ROOT/shots/list_scale.trace"
for n in ${LIST_NS:-100 500 1000 2000 5000}; do
  : > "$T"; MVU_TRACE="$T" MVU_PRELOAD=$n "$@" > /dev/null 2>&1 & P=$!
  waitwin || { echo "N=$n : pas de fenêtre"; kill $P; continue; }; sleep 2
  c() { xdotool mousemove $1 $2 click 1; }
  base=$(awk '/VmRSS/{print int($2/1024)}' /proc/$P/status)
  cpu() { awk '{print $14+$15}' /proc/$P/stat; }   # jiffies utilisateur+système du processus
  idle_wait() { # attend que le processus soit libre (< 3 jiffies en 0,4 s) ; renvoie les ms écoulées
    local t0 a b; t0=$(date +%s%N)
    while :; do a=$(cpu); sleep 0.4; b=$(cpu); [ $((b - a)) -lt 3 ] && break; [ $(( ($(date +%s%N) - t0) / 1000000 )) -gt 90000 ] && break; done
    echo $(( ($(date +%s%N) - t0) / 1000000 )); }
  s=$(date +%s%N); c 160 41
  for _ in $(seq 1 1200); do grep -q "tab=items" "$T" && break; sleep 0.02; done
  e=$(date +%s%N); first=$(grep "tab=items" "$T" | head -1 | grep -o ' ms=[0-9.]*' | tail -1 | cut -d= -f2)
  busy=$(idle_wait); r1=$(awk '/VmRSS/{print int($2/1024)}' /proc/$P/status)
  # cocher le premier élément (met à jour 1 ligne sur N) : latence du clic jusqu'au rendu, puis durée du rendu
  nl=$(wc -l < "$T"); s2=$(date +%s%N); c 36 155
  for _ in $(seq 1 1500); do [ "$(wc -l < "$T")" -gt "$nl" ] && break; sleep 0.02; done
  e2=$(date +%s%N); upd=$(tail -1 "$T" | grep -o ' ms=[0-9.]*' | tail -1 | cut -d= -f2); ok=$(tail -1 "$T" | grep -c "\[x\]")
  busy2=$(idle_wait)
  echo "N=$n : rendu F* + réconciliation ${first:-?} ms ; interface occupée ${busy} ms après le changement d'onglet ; cocher 1 élément : latence $(( (e2-s2)/1000000 )) ms (rendu ${upd:-?} ms, coché=$ok), occupée ${busy2} ms ensuite ; RSS $base -> $r1 Mo"
  kill $P; wait $P 2>/dev/null; sleep 1
done
