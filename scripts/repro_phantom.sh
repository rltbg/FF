#!/usr/bin/env bash
# Reproduit le défaut « paramètre de type fantôme » (docs/repro/PhantomTypeParam.fst) : extraction en bibliothèque
# (--custard_entry_module), puis la compilation F# doit échouer avec FS0035. Le script réussit si l'erreur attendue est observée
# (si elle disparaît, le défaut est corrigé : le script échoue pour qu'on le remarque).
set -uo pipefail
source "$(dirname "$0")/env.sh"
D=$(mktemp -d); cd "$D"; cp "$ROOT/docs/repro/PhantomTypeParam.fst" .
A=(--odir o --cache_dir c --already_cached Prims,FStar --warn_error -321)
fstar.exe "${A[@]}" --cache_checked_modules PhantomTypeParam.fst > /dev/null 2>&1 || { echo "VERIF KO"; exit 1; }
fstar.exe "${A[@]}" --codegen FSharp --custard_entry_module PhantomTypeParam PhantomTypeParam.fst -o o/P.fs > /dev/null 2>&1 || { echo "EXTRACT KO"; exit 1; }
out=$(cd o && dotnet build -c Release --nologo -v quiet 2>&1 | grep -m1 -o "error FS0035.*" | cut -c1-150)
rm -rf "$D"
if [ -n "$out" ]; then echo "défaut reproduit : $out"; else echo "FS0035 NON reproduit : le défaut a changé (voir docs/UPSTREAM-FSTAR.md)"; exit 1; fi
