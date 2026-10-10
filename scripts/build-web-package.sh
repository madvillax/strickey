#!/bin/zsh
set -euo pipefail
project_root="${0:A:h:h}"
version="${1:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$project_root/Resources/Info.plist")}"
[[ "$version" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]] || { print -u2 "Version must be X.Y.Z"; exit 1; }
# Build in a separate tree so packaging never replaces or stops the running local app.
work_root="$(mktemp -d "${TMPDIR:-/tmp}/strickey-web-package.XXXXXX")"
trap 'rm -rf "$work_root"' EXIT
cp "$project_root/Package.swift" "$work_root/Package.swift"
for directory in Sources Tests Resources scripts; do
    ditto "$project_root/$directory" "$work_root/$directory"
done
cd "$work_root"
zsh scripts/release.sh "$version"
zsh scripts/verify-release.sh "dist/Strickey-$version-universal.dmg"
node "$project_root/scripts/prepare-web-download.mjs" "$work_root/dist/Strickey-$version-universal.dmg"
