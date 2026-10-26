# Source ce fichier : définit ROOT, les chemins des outils et l'environnement .NET.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS="$ROOT/.tools"
FSTAR_TAG=v2026.10.25
DOTNET_VERSION=10.0.403
export DOTNET_ROOT="$TOOLS/dotnet"
export PATH="$TOOLS/dotnet:$TOOLS/fstar/bin:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1 DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
FSTAR_ARGS=(--odir "$ROOT/fst/_output" --cache_dir "$ROOT/fst/_cache" --already_cached Prims,FStar --warn_error -321)
# fstar_mode full|admit|lax : remplit FA (cache séparé par mode, les .checked dépendent des options)
fstar_mode() {
  case $1 in
    full)  FA=("${FSTAR_ARGS[@]}") ;;
    admit) FA=(--odir "$ROOT/fst/_output" --cache_dir "$ROOT/fst/_cache_admit" --already_cached Prims,FStar --warn_error -321 --admit_smt_queries true) ;;
    lax)   FA=(--odir "$ROOT/fst/_output" --cache_dir "$ROOT/fst/_cache_lax" --already_cached Prims,FStar --warn_error -321 --lax) ;;
    *) echo "mode inconnu: $1" >&2; return 2 ;;
  esac
}
