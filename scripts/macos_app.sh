#!/usr/bin/env bash
# Emballe une publication NativeAOT macOS (dossier) dans un bundle .app, le signe « ad hoc » (sans certificat) et le vérifie.
# usage : macos_app.sh <dossier_publication> <sortie.app> [exécutable=HostStatic] [version=1.0]
# Sans certificat « Developer ID » la signature n'est qu'ad hoc : l'app se lance localement ; après un téléchargement, macOS (Gatekeeper)
# la met en quarantaine : clic droit > Ouvrir, ou `xattr -dr com.apple.quarantine <app>`. Notarisation = certificat Apple, non fait ici.
set -euo pipefail
src=$1; app=$2; exe=${3:-HostStatic}; ver=${4:-1.0}
[ -x "$src/$exe" ] || { echo "exécutable absent : $src/$exe" >&2; exit 1; }
rm -rf "$app"; mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp -R "$src"/. "$app/Contents/MacOS/"
cat > "$app/Contents/Info.plist" <<P
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>F* MVU</string>
  <key>CFBundleDisplayName</key><string>F* MVU</string>
  <key>CFBundleIdentifier</key><string>net.fstar.mvu</string>
  <key>CFBundleExecutable</key><string>$exe</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$ver</string>
  <key>CFBundleVersion</key><string>$ver</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
P
python3 -I - "$app/Contents/Info.plist" "$exe" <<'P'
import plistlib,sys
d=plistlib.load(open(sys.argv[1],'rb')); assert d['CFBundleExecutable']==sys.argv[2]; print('Info.plist valide :',d['CFBundleIdentifier'])
P
if command -v codesign >/dev/null; then
  # bibliothèques et exécutables d'abord, puis le bundle (ordre demandé par Apple/Avalonia)
  find "$app/Contents/MacOS" -type f \( -name '*.dylib' -o -name "$exe" \) -exec codesign --force --sign - {} \;
  codesign --force --sign - "$app"
  codesign --verify --deep --strict --verbose=2 "$app"
else echo "codesign absent (pas macOS) : bundle non signé"; fi
