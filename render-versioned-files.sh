#!/usr/bin/env bash
# Renders control and Resources/Info.plist from their templates.
#   VERSION                Legacy Surf release (package and CFBundleShortVersionString)
#   SURF_BASE_VERSION      upstream Surf client this fork is based on; it is what
#                          the app reports to the Surf server as its version
#   COMPATIBILITY_VERSION  Surf protocol generation, must match the server
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
version="${VERSION:?VERSION is required}"
base_version="${SURF_BASE_VERSION:?SURF_BASE_VERSION is required}"
compatibility_version="${COMPATIBILITY_VERSION:?COMPATIBILITY_VERSION is required}"

semver='^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$'
if [[ ! "$version" =~ $semver ]]; then
  echo "invalid VERSION: $version" >&2
  exit 1
fi
if [[ ! "$base_version" =~ $semver ]]; then
  echo "invalid SURF_BASE_VERSION: $base_version" >&2
  exit 1
fi
if [[ ! "$compatibility_version" =~ ^[1-9][0-9]*$ ]]; then
  echo "invalid COMPATIBILITY_VERSION: $compatibility_version" >&2
  exit 1
fi
core_version="${version%%[-+]*}"
IFS=. read -r major minor patch <<< "$core_version"
if (( 10#$minor >= 1000 || 10#$patch >= 1000 )); then
  echo "VERSION minor and patch components must be below 1000: $version" >&2
  exit 1
fi
bundle_version=$((10#$major * 1000000 + 10#$minor * 1000 + 10#$patch))

render() {
  sed -e "s/@VERSION@/$version/g" \
      -e "s/@SURF_BASE_VERSION@/$base_version/g" \
      -e "s/@BUNDLE_VERSION@/$bundle_version/g" \
      -e "s/@COMPATIBILITY_VERSION@/$compatibility_version/g" \
      "$1" > "$2.tmp"
  # Rewrite only on change so make does not see a fresh plist every run.
  if cmp -s "$2.tmp" "$2"; then rm -f "$2.tmp"; else mv "$2.tmp" "$2"; fi
}

mkdir -p "$script_dir/Resources"
render "$script_dir/control.in" "$script_dir/control"
render "$script_dir/Info.plist.in" "$script_dir/Resources/Info.plist"
