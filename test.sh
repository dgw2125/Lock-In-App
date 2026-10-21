#!/bin/zsh
set -eu
cd "${0:A:h}"
source Tools/compiler-flags.sh
swiftc "${compiler_flags[@]}" Sources/Session.swift Sources/BrowserGuard.swift Sources/AppModel.swift Tests/main.swift -o /tmp/lockin-tests -framework AppKit -framework SwiftUI
/tmp/lockin-tests
