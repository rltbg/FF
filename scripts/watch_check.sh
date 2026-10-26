#!/usr/bin/env bash
# dotnet watch sur HostStatic : modifie le F# extrait puis le F# écrit à la main, relève la réaction.
# Variante : StartupHookSupport=true dans l environnement (lu par MSBuild comme propriété).
set -uo pipefail
source "$(dirname "$0")/env.sh"; source "$(dirname "$0")/xvfb.sh"
L="$ROOT/logs/watch.log"; : > "$L"
cp "$ROOT/app/Extracted/Extracted.fs" /tmp/Extracted.fs.bak; cp "$ROOT/app/Ui/Interp.fs" /tmp/Interp.fs.bak
cd "$ROOT/app"
dotnet watch --project HostStatic --non-interactive run > "$L" 2>&1 & W=$!
restore() { cp /tmp/Extracted.fs.bak "$ROOT/app/Extracted/Extracted.fs"; cp /tmp/Interp.fs.bak "$ROOT/app/Ui/Interp.fs"; kill $W 2>/dev/null; sleep 1
  ps -eo pid,args | awk '$2 ~ /HostStatic$/ {print $1}' | xargs -r kill 2>/dev/null; }
trap restore EXIT
waitwin || sleep 60; waitwin || { echo "KO: pas de fenêtre"; tail -5 "$L"; exit 1; }
sleep 2
step() { local n0; n0=$(wc -l < "$L"); local t0; t0=$(date +%s%3N); eval "$2"
  for _ in $(seq 1 300); do sleep 0.1; tail -n +$((n0+1)) "$L" | grep -q "Waiting for changes\|Hot reload succeeded\|Hot reload of changes succeeded" && break; done
  echo "[$1] $(( $(date +%s%3N) - t0 )) ms :"; tail -n +$((n0+1)) "$L" | grep -E "dotnet watch" | sed 's/^/    /'; }
step "F# extrait" "sed -i 's/\"Valeur : \"/\"Valeur W : \"/' '$ROOT/app/Extracted/Extracted.fs'"
waitwin; sleep 3
step "F# à la main (Interp.fs)" "sed -i 's/FontSize = 22.0/FontSize = 24.0/' '$ROOT/app/Ui/Interp.fs'"
