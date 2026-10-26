#!/usr/bin/env bash
# 10 lancements : délai jusqu'à la fenêtre X11 mappée, puis RSS 3 s après. usage : startup.sh label cmd...
set -uo pipefail
source "$(dirname "$0")/env.sh"; source "$(dirname "$0")/xvfb.sh"
label=$1; shift; ts=(); rs=()
for i in $(seq 1 10); do
  s=$(date +%s%N); "$@" >/dev/null 2>&1 & P=$!
  waitwin; e=$(date +%s%N); sleep 3
  rs+=($(awk '/VmRSS/{print $2}' /proc/$P/status)); kill $P; wait $P 2>/dev/null; sleep 0.5
  ts+=($(( (e-s)/1000000 )))
done
python3 - "$label" "${ts[*]}" "${rs[*]}" <<'PY'
import sys, statistics as st, math
l=sys.argv[1]; raw=list(map(int,sys.argv[2].split())); t=sorted(raw); r=sorted(map(int,sys.argv[3].split()))
p95=t[math.ceil(0.95*len(t))-1]
print(f"{l}: fenêtre en ms  1er={raw[0]} médiane={st.median(t)} p95={p95} min={t[0]} max={t[-1]} | RSS repos Ko médiane={st.median(r)} max={r[-1]}")
PY
