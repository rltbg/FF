#!/usr/bin/env bash
# Coût de 100 000 éléments DANS LE MODÈLE F* (programmes F* ftests/bench/TB*.fst, extraits, exécutés en JIT et en NativeAOT ;
# le temps est mesuré de l'extérieur, par différence entre phases : F* n'a pas d'horloge réalisée en F# — FStar.Date n'a pas de réalisation).
# TB1 = construction ; TB2 = construction + 20 Toggle ; TB3 = construction + 5 view. Mesures Xvfb/sans GPU non concernées (aucune interface).
set -euo pipefail
source "$(dirname "$0")/env.sh"
O="$ROOT/out/bench"; rm -rf "$O"; mkdir -p "$O"
cd "$ROOT/fst"; for m in "${FST_MODULES[@]}"; do fstar.exe "${FSTAR_ARGS[@]}" --cache_checked_modules $m.fst > /dev/null; done
cd "$ROOT/ftests"
A=("${FSTAR_ARGS[@]}" --warn_error -321-272 --include "$ROOT/fst" --include "$ROOT/ftests" --include "$ROOT/ftests/bench")
fstar.exe "${A[@]}" --cache_checked_modules TUtil.fst > /dev/null
t() { local s e; s=$(date +%s%N); "$@" > /dev/null; e=$(date +%s%N); echo $(( (e - s) / 1000000 )); }
printf '%-6s %-10s %s\n' phase mode "ms (3 passes)"
for b in TB1 TB2 TB3; do
  fstar.exe "${A[@]}" --cache_checked_modules bench/$b.fst > "$O/$b.verif" 2>&1 || { cat "$O/$b.verif" | head -20; exit 1; }
  mkdir -p "$O/$b"; fstar.exe "${A[@]}" --codegen FSharp --custard_main $b.main bench/$b.fst -o "$O/$b/$b.fs" > "$O/$b.extract" 2>&1 || { head -20 "$O/$b.extract"; exit 1; }
  (cd "$O/$b" && dotnet build -c Release --nologo -v quiet > build.log 2>&1 && dotnet publish -c Release -r linux-x64 --nologo -p:PublishAot=true -o aot > publish.log 2>&1) || { tail -5 "$O/$b/build.log"; exit 1; }
  printf '%-6s %-10s %s\n' $b JIT "$(for i in 1 2 3; do t dotnet "$O/$b/bin/Release/net10.0/$b.dll"; done | tr '\n' ' ')"
  printf '%-6s %-10s %s\n' $b AOT "$(for i in 1 2 3; do t "$O/$b/aot/$b"; done | tr '\n' ' ')"
done
