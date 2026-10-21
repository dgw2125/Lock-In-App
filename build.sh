#!/bin/zsh
set -eu
cd "${0:A:h}"
mkdir -p 'build/Lock In.app/Contents/MacOS'
source Tools/compiler-flags.sh
swiftc "${compiler_flags[@]}" -O -target arm64-apple-macosx14.0 Sources/Session.swift Sources/BrowserGuard.swift Sources/AppModel.swift Sources/main.swift -o 'build/Lock In.app/Contents/MacOS/LockIn' -framework AppKit -framework SwiftUI
cp Resources/Info.plist 'build/Lock In.app/Contents/Info.plist'
codesign --force --sign - 'build/Lock In.app'
printf 'Built: %s/build/Lock In.app\n' "$PWD"
