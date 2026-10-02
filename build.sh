#!/usr/bin/env bash
# Theos refuses to build in a path that contains spaces, such as
# "Surf Skeomorphic Version". This mirrors the sources into a space-free
# directory, runs make there with the same goals and variables, and copies the
# packages back into ./packages. `make` in this folder calls it automatically.
#
#   ./build.sh package            same as `make package`
#   LEGACYSURF_BUILD_DIR=/path ./build.sh package
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mirror="${LEGACYSURF_BUILD_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/legacysurf-theos}"
case "$mirror" in
  *' '*)
    echo "build.sh: the build directory must not contain spaces: $mirror" >&2
    exit 1
    ;;
esac
export THEOS="${THEOS:-$HOME/theos}"

mkdir -p "$mirror"
# The mirror keeps its own .theos so rebuilds stay incremental.
rsync -a --delete --exclude '/.theos/' --exclude '/packages/' --exclude '/.git/' \
  "$src/" "$mirror/"
make -C "$mirror" "$@"

if compgen -G "$mirror/packages/*.deb" > /dev/null; then
  mkdir -p "$src/packages"
  cp -p "$mirror"/packages/*.deb "$src/packages/"
fi
if [ -f "$mirror/.theos/last_package" ]; then
  echo "==> $src/packages/$(basename "$(tr -d '\r\n' < "$mirror/.theos/last_package")")"
fi
