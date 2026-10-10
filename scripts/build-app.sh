#!/bin/zsh
set -euo pipefail
project_root="${0:A:h:h}"
cd "$project_root"
configuration="${1:-release}"
architecture="${2:-native}"
if [[ "$configuration" != "release" && "$configuration" != "debug" ]] || [[ "$architecture" != "native" && "$architecture" != "universal" ]]; then
    print -u2 "Usage: scripts/build-app.sh [release|debug] [native|universal]"
    exit 1
fi
mkdir -p .build dist
staging_root="$(mktemp -d "$project_root/.build/app.XXXXXX")"
trap 'rm -rf "$staging_root"' EXIT
app_path="$staging_root/Strickey.app"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
if [[ "$architecture" == "universal" ]]; then
    for cpu in arm64 x86_64; do
        build_args=(-c "$configuration" --triple "$cpu-apple-macosx14.0" --scratch-path "$project_root/.build/$cpu")
        MACOSX_DEPLOYMENT_TARGET=14.0 swift build "${build_args[@]}"
        cpu_binary_dir="$(swift build "${build_args[@]}" --show-bin-path)"
        cp "$cpu_binary_dir/Strickey" "$staging_root/Strickey-$cpu"
        if [[ "$cpu" == "arm64" ]]; then binary_dir="$cpu_binary_dir"; fi
    done
    lipo -create "$staging_root/Strickey-arm64" "$staging_root/Strickey-x86_64" -output "$app_path/Contents/MacOS/Strickey"
else
    swift build -c "$configuration"
    binary_dir="$(swift build -c "$configuration" --show-bin-path)"
    cp "$binary_dir/Strickey" "$app_path/Contents/MacOS/Strickey"
fi
# SwiftPM resources must travel with the app; installed copies never depend on .build.
resource_bundle="$binary_dir/Strickey_StrickeyCore.bundle"
[[ -d "$resource_bundle" ]] || { print -u2 "Missing resource bundle: $resource_bundle"; exit 1; }
ditto "$resource_bundle" "$app_path/Contents/Resources/Strickey_StrickeyCore.bundle"
cp Resources/Info.plist "$app_path/Contents/Info.plist"
if [[ -n "${STRICKEY_VERSION:-}" ]]; then
    [[ "$STRICKEY_VERSION" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]] || { print -u2 "Version must be X.Y.Z"; exit 1; }
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $STRICKEY_VERSION" "$app_path/Contents/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $STRICKEY_VERSION" "$app_path/Contents/Info.plist"
fi
swift scripts/make-icon.swift "$staging_root/Strickey.iconset"
iconutil -c icns "$staging_root/Strickey.iconset" -o "$app_path/Contents/Resources/AppIcon.icns"
plutil -lint "$app_path/Contents/Info.plist"
identity="${STRICKEY_SIGNING_IDENTITY:--}"
sign_args=(--force --sign "$identity" --options runtime)
if [[ "$identity" != "-" ]]; then sign_args+=(--timestamp); fi
codesign "${sign_args[@]}" "$app_path"
codesign --verify --strict "$app_path"
# Replace only the generated app, after the staged bundle has passed signature validation.
# Stop this exact project copy first: modifying a running executable can produce
# a macOS CODESIGNING / Invalid Page termination or leave the old build running.
target_executable="$project_root/dist/Strickey.app/Contents/MacOS/Strickey"
for running_pid in ${(f)$(pgrep -x Strickey || true)}; do
    [[ "$(ps -p "$running_pid" -o comm=)" == "$target_executable" ]] || continue
    print "Stopping running project build (PID $running_pid) before replacement"
    kill -TERM "$running_pid" 2>/dev/null || true
    for attempt in {1..50}; do
        kill -0 "$running_pid" 2>/dev/null || break
        sleep 0.1
    done
    if kill -0 "$running_pid" 2>/dev/null; then
        print -u2 "Strickey has not exited. Quit it and rebuild; the current bundle was preserved."
        exit 1
    fi
done
rm -rf "$project_root/dist/Strickey.app"
mv "$app_path" "$project_root/dist/Strickey.app"
print "Built $project_root/dist/Strickey.app ($architecture)"
