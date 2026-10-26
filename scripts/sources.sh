#!/usr/bin/env bash
# Récupère le CODE SOURCE des projets utilisés, aux versions exactes du banc, dans .tools/src/ (non versionné).
# À consulter AVANT d'écrire du code qui s'appuie dessus (F* et Avalonia sont peu courants : ne pas deviner les API).
set -euo pipefail
source "$(dirname "$0")/env.sh"
S="$TOOLS/src"; mkdir -p "$S"
clone() { # url tag dossier
  if [ -d "$S/$3/.git" ]; then echo "déjà présent : $3 ($(git -C "$S/$3" describe --tags --always))"; return; fi
  git clone -q --depth 1 --branch "$2" "$1" "$S/$3" && echo "cloné : $3 @ $2"
}
clone https://github.com/FStarLang/FStar "$FSTAR_TAG" FStar          # ulib/ (bibliothèque F*), src/custard/ (backend F#), doc/ref/custard.md
clone https://github.com/AvaloniaUI/Avalonia 12.1.4 Avalonia         # src/Avalonia.Controls, Avalonia.Base, Avalonia.X11, ...
echo
echo "F*       : $S/FStar/ulib  $S/FStar/src/custard  $S/FStar/doc/ref/custard.md  $S/FStar/tests/custard"
echo "Avalonia : $S/Avalonia/src"
echo "Autres sources utiles : paquets NuGet (~/.nuget/packages/*/lib/*/*.xml pour la doc XML) ; FSharp.Core ;"
echo "                        runtime .NET (https://github.com/dotnet/runtime, tag v10.0.x) pour AssemblyLoadContext, NativeAOT."
