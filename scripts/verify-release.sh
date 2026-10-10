#!/bin/zsh
set -euo pipefail
project_root="${0:A:h:h}"
cd "$project_root"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
dmg_path="${1:-dist/Strickey-$version-universal.dmg}"
dmg_path="${dmg_path:A}"
[[ -f "$dmg_path" && -f "$dmg_path.sha256" ]] || { print -u2 "DMG and checksum file are required."; exit 1; }
(cd "${dmg_path:h}" && shasum -a 256 -c "${dmg_path:t}.sha256")
hdiutil verify "$dmg_path"
mount_root="$(mktemp -d "$project_root/.build/verify-dmg.XXXXXX")"
cleanup() {
    hdiutil detach "$mount_root" >/dev/null 2>&1 || true
    rmdir "$mount_root" 2>/dev/null || true
}
trap cleanup EXIT
hdiutil attach "$dmg_path" -readonly -nobrowse -mountpoint "$mount_root"
app_path="$mount_root/Strickey.app"
codesign --verify --strict "$app_path"
architectures="$(lipo -archs "$app_path/Contents/MacOS/Strickey")"
[[ "$architectures" == *arm64* && "$architectures" == *x86_64* ]] || { print -u2 "Expected universal app, got: $architectures"; exit 1; }
[[ "$(readlink "$mount_root/Applications")" == "/Applications" ]] || { print -u2 "Missing Applications shortcut"; exit 1; }
resource_bundle="$app_path/Contents/Resources/Strickey_StrickeyCore.bundle"
[[ -f "$resource_bundle/Contents/Resources/CherryMX/LICENSE-Mechvibes.txt" || -f "$resource_bundle/CherryMX/LICENSE-Mechvibes.txt" ]] || { print -u2 "Missing recording license"; exit 1; }
"$app_path/Contents/MacOS/Strickey" --smoke-test
print "Verified mounted DMG, bundled recordings, license, signatures, and $architectures."
