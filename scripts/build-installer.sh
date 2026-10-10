#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUTPUT=${1:-"$ROOT/dist"}
mkdir -p "$OUTPUT"
OUTPUT=$(cd "$OUTPUT" && pwd)
WORK=$(mktemp -d "${TMPDIR:-/tmp}/finder-open-with.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

if ! xcodebuild -quiet -project "$ROOT/FinderOpenWith.xcodeproj" \
    -scheme FinderOpenWith -configuration Release \
    -derivedDataPath "$WORK/DerivedData" \
    ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO build > "$WORK/build.log" 2>&1; then
    cat "$WORK/build.log" >&2
    exit 1
fi

APP="$WORK/DerivedData/Build/Products/Release/Finder Open With.app"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")
BUILD=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Contents/Info.plist")
PKG_VERSION="$VERSION.$BUILD"
NAME="FinderOpenWith-$VERSION-universal.pkg"
codesign --verify --deep --strict --verbose=2 "$APP"
for ARCH in arm64 x86_64; do
    lipo "$APP/Contents/MacOS/Finder Open With" -verify_arch "$ARCH"
    lipo "$APP/Contents/PlugIns/FinderOpenWithFinderExtension.appex/Contents/MacOS/FinderOpenWithFinderExtension" -verify_arch "$ARCH"
done

mkdir -p "$WORK/root/Applications"
ditto "$APP" "$WORK/root/Applications/Finder Open With.app"
pkgbuild --analyze --root "$WORK/root" "$WORK/components.plist"
/usr/bin/python3 - "$WORK/components.plist" <<'PY'
import plistlib, sys
path = sys.argv[1]
with open(path, 'rb') as file:
    components = plistlib.load(file)
for component in components:
    component['BundleIsRelocatable'] = False
    component['BundleOverwriteAction'] = 'upgrade'
with open(path, 'wb') as file:
    plistlib.dump(components, file)
PY

pkgbuild --root "$WORK/root" --component-plist "$WORK/components.plist" \
    --identifier jp.miyazawahayato.FinderOpenWith.installer \
    --version "$PKG_VERSION" --install-location / \
    --ownership recommended "$WORK/FinderOpenWith-component.pkg"
sed "s/@VERSION@/$PKG_VERSION/g" "$ROOT/packaging/Distribution.xml" > "$WORK/Distribution.xml"
productbuild --distribution "$WORK/Distribution.xml" \
    --resources "$ROOT/packaging/resources" --package-path "$WORK" "$OUTPUT/$NAME"
cp "$ROOT/docs/INSTALL.md" "$OUTPUT/INSTALL.md"
(cd "$OUTPUT" && shasum -a 256 "$NAME" INSTALL.md > SHA256SUMS.txt)
echo "Created: $OUTPUT/$NAME"
echo 'Developer ID signing and notarization are not included.'
