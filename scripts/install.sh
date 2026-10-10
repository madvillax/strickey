#!/bin/zsh
set -euo pipefail

repository="${STRICKEY_GITHUB_REPOSITORY:-madvillax/strickey}"
version="${1:-latest}"
install_directory="${2:-${STRICKEY_INSTALL_DIRECTORY:-$HOME/Applications}}"

[[ "$(uname -s)" == "Darwin" ]] || { print -u2 "strickey requires macOS 14 or later."; exit 1; }
[[ "$repository" =~ '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' ]] || { print -u2 "Repository must be OWNER/REPO."; exit 1; }

if [[ "$version" == "latest" ]]; then
    latest_url="$(curl --fail --silent --show-error --location --output /dev/null --write-out '%{url_effective}' \
        "https://github.com/$repository/releases/latest")"
    tag="${latest_url##*/}"
    [[ "$tag" == v* ]] || { print -u2 "Could not resolve the latest published strickey release."; exit 1; }
    version="${tag#v}"
fi
[[ "$version" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]] || { print -u2 "Version must be X.Y.Z or latest."; exit 1; }

if pgrep -x Strickey >/dev/null 2>&1; then
    print -u2 "Quit strickey before installing or updating it, then run this installer again."
    exit 1
fi

work_directory="$(mktemp -d "${TMPDIR:-/tmp}/strickey-install.XXXXXX")"
mount_point="$work_directory/mount"
mkdir -p "$mount_point"
mounted=0
target_app=""
backup_app=""
install_in_progress=0
cleanup() {
    if (( mounted )); then
        hdiutil detach "$mount_point" >/dev/null 2>&1 || true
    fi
    if [[ -n "$backup_app" && -d "$backup_app" ]]; then
        if [[ -e "$target_app" || -L "$target_app" ]]; then rm -rf "$target_app"; fi
        mv "$backup_app" "$target_app"
    elif (( install_in_progress )) && [[ -e "$target_app" || -L "$target_app" ]]; then
        rm -rf "$target_app"
    fi
    rm -rf "$work_directory"
}
trap cleanup EXIT

dmg_name="Strickey-$version-universal.dmg"
release_url="https://github.com/$repository/releases/download/v$version"
curl --fail --silent --show-error --location --retry 2 --connect-timeout 10 --max-time 300 \
    "$release_url/$dmg_name" --output "$work_directory/$dmg_name"
curl --fail --silent --show-error --location --retry 2 --connect-timeout 10 --max-time 90 \
    "$release_url/$dmg_name.sha256" --output "$work_directory/$dmg_name.sha256"
(cd "$work_directory" && shasum -a 256 -c "$dmg_name.sha256")
hdiutil verify "$work_directory/$dmg_name"
hdiutil attach "$work_directory/$dmg_name" -readonly -nobrowse -mountpoint "$mount_point" >/dev/null
mounted=1
source_app="$mount_point/Strickey.app"
[[ -d "$source_app" ]] || { print -u2 "The release DMG does not contain Strickey.app."; exit 1; }

mkdir -p "$install_directory"
install_directory="${install_directory:A}"
target_app="$install_directory/Strickey.app"
if [[ -e "$target_app" || -L "$target_app" ]]; then
    backup_app="$install_directory/.Strickey.backup.$$.app"
    [[ ! -e "$backup_app" ]] || { print -u2 "Temporary backup already exists: $backup_app"; exit 1; }
    mv "$target_app" "$backup_app"
fi
install_in_progress=1
ditto "$source_app" "$target_app"
if [[ -n "$backup_app" ]]; then
    rm -rf "$backup_app"
    backup_app=""
fi
install_in_progress=0

print "Installed strickey $version at $target_app"
print "Open it and enable Input Monitoring in System Settings > Privacy & Security."
open "$target_app"
