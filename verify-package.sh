#!/usr/bin/env bash
# Checks the last built Legacy Surf package: metadata, both architectures and
# their minimum iOS versions, the iOS 6 weak import, Info.plist, icons and the
# OS-specific icon selector. Uses the Theos toolchain, so it runs on Linux.
#
#   ./verify-package.sh [path/to/package.deb]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEOS="${THEOS:-$HOME/theos}"
TOOLS="$THEOS/toolchain/linux/iphone/bin"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
COMPATIBILITY_VERSION="$(tr -d '[:space:]' < "$ROOT/COMPATIBILITY_VERSION")"
PACKAGE_ID=com.legacyreborn.legacysurf

package="${1:-}"
if [ -z "$package" ]; then
  package="$(ls -t "$ROOT"/packages/${PACKAGE_ID}_*_iphoneos-arm.deb 2>/dev/null | head -n 1 || true)"
fi
if [ -z "$package" ] || [ ! -f "$package" ]; then
  echo "No package to verify; run make package first" >&2
  exit 1
fi

fail() { echo "FAIL: $*" >&2; exit 1; }

[ "$(dpkg-deb -f "$package" Package)" = "$PACKAGE_ID" ] || fail "unexpected package identifier"
[ "$(dpkg-deb -f "$package" Architecture)" = "iphoneos-arm" ] || fail "unexpected architecture"
[ "$(dpkg-deb -f "$package" X-Surf-Compatibility)" = "$COMPATIBILITY_VERSION" ] ||
  fail "package compatibility does not match $COMPATIBILITY_VERSION"
case "$(dpkg-deb -f "$package" Version)" in
  "$VERSION"|"$VERSION"-*|"$VERSION"+*) ;;
  *) fail "package version is not $VERSION" ;;
esac
# iOS 6 era dpkg only understands gzip members.
if ar t "$package" | grep -q 'data.tar.\(xz\|zst\|lzma\|bz2\)'; then
  fail "data member is not gzip-compressed"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
dpkg-deb -x "$package" "$tmp/root"
dpkg-deb -e "$package" "$tmp/DEBIAN"
app="$tmp/root/Applications/LegacySurf.app"
binary="$app/LegacySurf"
[ -f "$binary" ] || fail "missing $binary"

"$TOOLS/lipo" "$binary" -verify_arch armv7 arm64 || fail "binary must contain armv7 and arm64"
minimum_version() {
  "$TOOLS/otool" -arch "$1" -l "$binary" | awk '
    $1 == "cmd" && ($2 == "LC_VERSION_MIN_IPHONEOS" || $2 == "LC_BUILD_VERSION") { in_cmd = 1; next }
    !found && in_cmd && ($1 == "version" || $1 == "minos") { print $2; found = 1 }'
}
case "$(minimum_version armv7)" in 6.0|6.0.0) ;; *) fail "armv7 slice must target iOS 6.0" ;; esac
case "$(minimum_version arm64)" in 7.0|7.0.0) ;; *) fail "arm64 slice must target iOS 7.0" ;; esac

# iOS 6 lacks this iOS 8 symbol; a strong import would stop dyld at launch.
"$TOOLS/nm" -arch armv7 -m "$binary" | grep '_AVSampleBufferDisplayLayerFailedToDecodeNotification' |
  grep -q 'weak external' || fail "display-layer notification must stay weak-imported"

plist="$app/Info.plist"
key_value() { sed -n "/<key>$1<\/key>/{n;s/^[[:space:]]*//;p;}" "$plist" | head -n 1; }
[ "$(key_value CFBundleIdentifier)" = "<string>$PACKAGE_ID</string>" ] || fail "CFBundleIdentifier"
[ "$(key_value CFBundleExecutable)" = "<string>LegacySurf</string>" ] || fail "CFBundleExecutable"
[ "$(key_value CFBundleDisplayName)" = "<string>Legacy Surf</string>" ] || fail "CFBundleDisplayName"
[ "$(key_value MinimumOSVersion)" = "<string>6.0</string>" ] || fail "MinimumOSVersion"
[ "$(key_value CFBundleShortVersionString)" = "<string>$VERSION</string>" ] || fail "CFBundleShortVersionString"
[ "$(key_value SurfCompatibilityVersion)" = "<integer>$COMPATIBILITY_VERSION</integer>" ] ||
  fail "SurfCompatibilityVersion"
grep -q '<string>Lucide.ttf</string>' "$plist" || fail "Lucide font is not registered"
grep -q '<key>CFBundleIcons' "$plist" && fail "rootful package must use CFBundleIconFiles"

verify_png() {
  case "$(file -b "$app/$1")" in
    "PNG image data, $2, 8-bit"*) ;;
    *) fail "$1 is not a $2 PNG" ;;
  esac
}
verify_png Icon.png "57 x 57"
verify_png Icon@2x.png "114 x 114"
verify_png Icon-72.png "72 x 72"
verify_png Icon-72@2x.png "144 x 144"
verify_png Icon-60@2x.png "120 x 120"
verify_png Icon-76~ipad.png "76 x 76"
verify_png Icon-83.5@2x.png "167 x 167"
verify_png IconSets/Classic/Icon-60@2x.png "120 x 120"
verify_png IconSets/Modern/Icon-60@2x.png "120 x 120"
verify_png brand-mark.png "144 x 144"
verify_png Default@2x.png "640 x 960"
verify_png Default-568h@2x.png "640 x 1136"
for resource in Lucide.ttf ThirdPartyNotices/LICENSE.txt ThirdPartyNotices/README.md \
                ThirdPartyNotices/DETA-SURF-LICENSE.txt ThirdPartyNotices/LUCIDE-LICENSE.txt \
                ThirdPartyNotices/QUIRC-LICENSE.txt; do
  [ -s "$app/$resource" ] || fail "missing $resource"
done
for leaked in Info.plist.in LegacySurf.entitlements icon-57.png icon-60.png; do
  [ -e "$app/$leaked" ] && fail "$leaked must not be inside the bundle"
done

selector="$tmp/root/usr/libexec/legacysurf-select-icons"
[ -x "$selector" ] || fail "missing executable icon selector"
LEGACYSURF_APP_DIR="$app" LEGACYSURF_SYSTEM_VERSION=6.1.3 "$selector"
cmp -s "$app/Icon-60@2x.png" "$app/IconSets/Classic/Icon-60@2x.png" || fail "iOS 6 must get the classic icon"
LEGACYSURF_APP_DIR="$app" LEGACYSURF_SYSTEM_VERSION=8.4 "$selector"
cmp -s "$app/Icon-60@2x.png" "$app/IconSets/Modern/Icon-60@2x.png" || fail "iOS 7+ must get the modern icon"
grep -q '/usr/libexec/legacysurf-select-icons' "$tmp/DEBIAN/postinst" || fail "postinst must select icons"

# Nothing may collide with an installed upstream Surf.
for path in usr/libexec/surf-update-v2 usr/libexec/surf-select-icons Applications/Surf.app; do
  [ -e "$tmp/root/$path" ] && fail "$path belongs to upstream Surf"
done

echo "Verified $(basename "$package"): armv7 iOS 6.0, arm64 iOS 7.0, version $VERSION"
