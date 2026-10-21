#!/bin/zsh
set -eu
cd "${0:A:h}"
mkdir -p build
source Tools/compiler-flags.sh
# Compile separately so rebuilding never truncates the running app's executable.
app_stage=$(mktemp -d "$PWD/build/stage.XXXXXX")
trap 'rm -rf "$app_stage"' EXIT
app_bundle="$app_stage/Lock In.app"
mkdir -p "$app_bundle/Contents/MacOS" "$app_bundle/Contents/Resources"
swiftc "${compiler_flags[@]}" -O -target arm64-apple-macosx14.0 Sources/Session.swift Sources/BrowserGuard.swift Sources/AppModel.swift Sources/main.swift -o "$app_bundle/Contents/MacOS/LockIn" -framework AppKit -framework SwiftUI
swiftc "${compiler_flags[@]}" Tools/CreateIcon.swift -o "$app_stage/create-icon" -framework AppKit
"$app_stage/create-icon" "$app_stage/AppIcon.iconset"
python3 Tools/pack-icon.py "$app_stage/AppIcon.iconset" "$app_bundle/Contents/Resources/AppIcon.icns"
cp Resources/Info.plist "$app_bundle/Contents/Info.plist"
codesign --force --sign - "$app_bundle"
codesign --verify "$app_bundle"
if [[ -d 'build/Lock In.app' ]]; then
    archive_dir=$(mktemp -d "$PWD/build/previous.XXXXXX")
    mv 'build/Lock In.app' "$archive_dir/Lock In.app"
fi
mv "$app_bundle" 'build/Lock In.app'
printf 'Built: %s/build/Lock In.app\n' "$PWD"
