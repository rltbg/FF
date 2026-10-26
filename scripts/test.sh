#!/usr/bin/env bash
# Suite de tests sous JIT puis sous NativeAOT.
set -euo pipefail
source "$(dirname "$0")/env.sh"
echo "JIT: $(dotnet "$ROOT/app/Tests/bin/Release/net10.0/Tests.dll")"
echo "AOT: $("$ROOT/out/Tests/Tests")"
