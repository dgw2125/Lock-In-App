# Sourced by build/test scripts. Work around a stale duplicate CLT module map
# using a compiler-only virtual filesystem overlay; system files are untouched.
compiler_flags=(-swift-version 5 -module-cache-path /tmp/lockin-swift-cache)
if [[ -f /Library/Developer/CommandLineTools/usr/include/swift/module.modulemap && -f /Library/Developer/CommandLineTools/usr/include/swift/bridging.modulemap ]]; then
    mkdir -p build/compiler
    : > build/compiler/empty.modulemap
    python3 - <<'PY'
import json, os
with open('build/compiler/overlay.json', 'w') as f:
    json.dump({'version': 0, 'roots': [{'type': 'file', 'name': '/Library/Developer/CommandLineTools/usr/include/swift/module.modulemap', 'external-contents': os.path.abspath('build/compiler/empty.modulemap')}]}, f)
PY
    compiler_flags+=(-vfsoverlay "$PWD/build/compiler/overlay.json" -Xcc -ivfsoverlay -Xcc "$PWD/build/compiler/overlay.json")
fi
