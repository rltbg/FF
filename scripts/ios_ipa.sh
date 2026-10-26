#!/usr/bin/env bash
# Emballe un .app iOS (appareil, arm64) dans un .ipa NON SIGNÉ et le vérifie.
# usage : ios_ipa.sh <dossier_contenant_le_.app | chemin.app> <sortie.ipa>
# Un .ipa non signé ne s'installe PAS tel quel sur un iPhone : il faut le re-signer (AltStore, Sideloadly, TrollStore, ou
# `codesign` avec votre certificat + profil de provisionnement). L'App Store / TestFlight exigent un compte développeur Apple.
set -euo pipefail
in=$1; out=$(cd "$(dirname "$2")" && pwd)/$(basename "$2")
if [[ "$in" == *.app && -d "$in" ]]; then app=$in; else app=$(find "$in" -maxdepth 6 -name '*.app' -type d | head -1); fi
[ -n "${app:-}" ] && [ -d "$app" ] || { echo "aucun .app trouvé sous $in" >&2; exit 1; }
t=$(mktemp -d); mkdir "$t/Payload"; cp -R "$app" "$t/Payload/"
rm -f "$out"; (cd "$t" && zip -qr -X "$out" Payload)
rm -rf "$t"
echo "ipa : $out ($(du -h "$out" | cut -f1)) ; app : $(basename "$app")"
# vérifications : Info.plist, exécutable Mach-O arm64
v=$(mktemp -d); unzip -q "$out" -d "$v"; a=$(ls -d "$v"/Payload/*.app)
python3 -I - "$a/Info.plist" <<'P'
import plistlib,sys
d=plistlib.load(open(sys.argv[1],'rb'))
print('CFBundleIdentifier =',d['CFBundleIdentifier'],'; CFBundleExecutable =',d['CFBundleExecutable'],'; MinimumOSVersion =',d.get('MinimumOSVersion'))
print('UIDeviceFamily =',d.get('UIDeviceFamily'),'; DTPlatformName =',d.get('DTPlatformName'))
P
exe=$(python3 -I -c "import plistlib,sys;print(plistlib.load(open(sys.argv[1],'rb'))['CFBundleExecutable'])" "$a/Info.plist")
info=$(file "$a/$exe"); echo "$info"
case "$info" in *"Mach-O 64-bit"*arm64*) ;; *) echo "l'exécutable n'est pas un Mach-O arm64" >&2; exit 1;; esac
rm -rf "$v"
