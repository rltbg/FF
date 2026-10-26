#!/bin/bash
# usage: loop.sh [full|lax] [build-target-dir]  -- chronomètre chaque étape de la boucle F* -> F#
export PATH=/home/user/w/dotnet:/home/user/w/fstar/fstar/bin:$PATH DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1 DOTNET_ROOT=/home/user/w/dotnet
MODE=${1:-full}; PROJ=/home/user/w/proj; cd $PROJ/fst
CD=_cache; [ "$MODE" = lax ] && CD=_cache_lax
A="--odir _output --cache_dir $CD --already_cached Prims,FStar --warn_error -321"
[ "$MODE" = lax ] && A="$A --admit_smt_queries true"
now() { date +%s.%N; }
t0=$(now)
(fstar.exe $A --cache_checked_modules Core.fst && fstar.exe $A --cache_checked_modules App.fst) > $PROJ/loop.check.log 2>&1 || { echo "CHECK FAILED"; tail -15 $PROJ/loop.check.log; exit 1; }
t1=$(now)
rm -rf $PROJ/gen; mkdir -p $PROJ/gen
fstar.exe $A --codegen FSharp --custard_entry_module Core --custard_entry_module App App.fst -o $PROJ/gen/Extracted.fs > $PROJ/loop.extract.log 2>&1 || { echo "EXTRACT FAILED"; tail -15 $PROJ/loop.extract.log; exit 1; }
t2=$(now)
cp $PROJ/gen/Extracted.fs $PROJ/app/Extracted/Extracted.fs
cd $PROJ/app
dotnet build Extracted -c Release --nologo > $PROJ/loop.build.log 2>&1 || { echo "BUILD FAILED"; grep -E "error" $PROJ/loop.build.log | head; exit 1; }
t3=$(now)
printf "mode=%s check=%.2fs extract=%.2fs build=%.2fs total=%.2fs\n" $MODE $(echo "$t1-$t0"|bc) $(echo "$t2-$t1"|bc) $(echo "$t3-$t2"|bc) $(echo "$t3-$t0"|bc)
