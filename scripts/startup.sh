#!/bin/bash
# usage: startup.sh label cmd... ; 10 exécutions ; temps jusqu'à fenêtre "F* MVU" puis RSS à +3 s
export DISPLAY=:99 PATH=/home/user/w/dotnet:$PATH DOTNET_ROOT=/home/user/w/dotnet DOTNET_CLI_TELEMETRY_OPTOUT=1
label=$1; shift
ts=(); rs=()
for i in $(seq 1 10); do
  s=$(date +%s%N); "$@" >/dev/null 2>&1 & P=$!
  while ! xwininfo -root -tree | grep -q 'F\* MVU'; do sleep 0.005; done
  e=$(date +%s%N); sleep 3
  r=$(grep VmRSS /proc/$P/status | awk '{print $2}')
  kill $P; wait $P 2>/dev/null; sleep 0.5
  ts+=($(( (e-s)/1000000 ))); rs+=($r)
done
python3 - "$label" "${ts[*]}" "${rs[*]}" <<'PY'
import sys,statistics as st
l=sys.argv[1]; t=sorted(map(int,sys.argv[2].split())); r=sorted(map(int,sys.argv[3].split()))
p95=lambda v:v[min(len(v)-1,int(round(0.95*len(v)+0.4))-1)]
print(f"{l}: démarrage ms  1er={sys.argv[2].split()[0]} médiane={st.median(t)} p95={p95(t)} min={t[0]} max={t[-1]} | RSS idle Ko médiane={st.median(r)} max={r[-1]}")
PY
