#!/usr/bin/env bash
# Suite de tests : entièrement en F* (ftests/), extraite puis exécutée sous JIT et sous NativeAOT. Voir ftests.sh.
exec "$(dirname "$0")/ftests.sh" "$@"
