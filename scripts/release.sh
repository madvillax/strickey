#!/bin/zsh
set -euo pipefail
project_root="${0:A:h:h}"
cd "$project_root"
version="${1:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)}"
repository="${STRICKEY_GITHUB_REPOSITORY:-madvillax/strickey}"
[[ "$version" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]] || { print -u2 "Version must be X.Y.Z"; exit 1; }
[[ "$repository" =~ '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' ]] || { print -u2 "Repository must be OWNER/REPO"; exit 1; }
identity="${STRICKEY_SIGNING_IDENTITY:--}"
notary_profile="${STRICKEY_NOTARY_PROFILE:-}"
notarize() {
    local archive="$1"
    local report="$2"
    xcrun notarytool submit "$archive" --keychain-profile "$notary_profile" --wait --output-format json > "$report"
    python3 - "$report" <<'PY'
import json, sys
from pathlib import Path
report = json.loads(Path(sys.argv[1]).read_text())
if report.get('status') != 'Accepted':
    sys.exit(f"Notarization was not accepted. See {sys.argv[1]} and fetch the notarytool log.")
print(f"Notarization accepted: {report['id']}")
PY
}
if [[ -n "$notary_profile" && "$identity" == "-" ]]; then
    print -u2 "Notarization requires STRICKEY_SIGNING_IDENTITY (Developer ID Application)."
    exit 1
fi
STRICKEY_VERSION="$version" ./scripts/build-app.sh release universal
app_path="$project_root/dist/Strickey.app"
"$app_path/Contents/MacOS/Strickey" --smoke-test
if [[ -n "$notary_profile" ]]; then
    notarization_zip="$project_root/dist/Strickey-$version-notarization.zip"
    ditto -c -k --keepParent "$app_path" "$notarization_zip"
    notarize "$notarization_zip" "$project_root/dist/notarization-app.json"
    xcrun stapler staple "$app_path"
    xcrun stapler validate "$app_path"
fi
staging_root="$(mktemp -d "$project_root/.build/dmg.XXXXXX")"
trap 'rm -rf "$staging_root"' EXIT
ditto "$app_path" "$staging_root/Strickey.app"
ln -s /Applications "$staging_root/Applications"
cat > "$staging_root/Install.txt" <<'INSTALL'
Drag Strickey.app into Applications, then open it from Applications.
Enable strickey in System Settings > Privacy & Security > Input Monitoring.
Quit and reopen after granting access. Choose Launch at login in the menu bar panel.
Sounds and preferences are local. No text or keystroke history is recorded.
INSTALL
dmg_path="$project_root/dist/Strickey-$version-universal.dmg"
hdiutil create -volname "strickey" -srcfolder "$staging_root" -format UDZO -ov "$dmg_path"
if [[ "$identity" != "-" ]]; then
    codesign --sign "$identity" --timestamp "$dmg_path"
fi
if [[ -n "$notary_profile" ]]; then
    notarize "$dmg_path" "$project_root/dist/notarization-dmg.json"
    xcrun stapler staple "$dmg_path"
    xcrun stapler validate "$dmg_path"
fi
hdiutil verify "$dmg_path"
(cd dist && shasum -a 256 "${dmg_path:t}" > "${dmg_path:t}.sha256")
if [[ -n "$notary_profile" ]]; then
    distribution="Developer ID signed and notarized"
else
    distribution="Not notarized; Gatekeeper may block downloaded copies"
fi
cat > "$project_root/dist/release-notes.md" <<NOTES
# strickey $version

- Recorded Cherry MX Red, Brown, and Blue switches with PBT keycaps.
- Neutral Liquid Glass panel, built-in keyboard volume, and launch at login.
- Universal macOS app: Apple Silicon and Intel, macOS 14 or later.
- MIT-licensed recordings and attribution are included in the app.

Distribution: $distribution.

Install the DMG by dragging Strickey.app into Applications. Enable Input Monitoring
and quit/reopen to start typing sounds. No Accessibility access is required.

Install the latest published release from Terminal:

\`\`\`sh
curl -fsSL https://raw.githubusercontent.com/$repository/main/scripts/install.sh -o /tmp/strickey-install.sh
STRICKEY_GITHUB_REPOSITORY=$repository zsh /tmp/strickey-install.sh
\`\`\`
NOTES
print "Ready: $dmg_path"
print "Checksum: $dmg_path.sha256"
print "$distribution"
