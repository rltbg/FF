#!/usr/bin/env bash
# Installe F* (release binaire) et le SDK .NET officiel dans .tools/. Idempotent. `setup.sh fstar` : F* seulement (CI : .NET vient de setup-dotnet).
set -euo pipefail
source "$(dirname "$0")/env.sh"
mkdir -p "$TOOLS"
if [ ! -x "$TOOLS/fstar/bin/fstar.exe" ]; then
  url="https://github.com/FStarLang/FStar/releases/download/$FSTAR_TAG/fstar-$FSTAR_TAG-Linux-x86_64.tar.gz"
  echo "F*: $url"
  curl -fsSL "$url" -o "$TOOLS/fstar.tgz"
  sha256sum "$TOOLS/fstar.tgz"
  tar xzf "$TOOLS/fstar.tgz" -C "$TOOLS" && rm "$TOOLS/fstar.tgz"
fi
if [ "${1:-}" != fstar ] && [ ! -x "$TOOLS/dotnet/dotnet" ]; then
  curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$TOOLS/dotnet-install.sh"
  bash "$TOOLS/dotnet-install.sh" --version "$DOTNET_VERSION" --install-dir "$TOOLS/dotnet"
fi
fstar.exe --version | head -1
[ "${1:-}" = fstar ] || dotnet --version
