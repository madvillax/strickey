#!/bin/zsh
set -euo pipefail
project_root="${0:A:h:h}"
cd "$project_root"

# Some CLT releases ship the Swift Testing plugin in a nested directory that
# SwiftPM's default build engine does not discover. Full Xcode normally resolves it.
swift_compiler="$(xcrun --find swiftc)"
testing_plugin="${swift_compiler:h:h}/lib/swift/host/plugins/testing/libTestingMacros.dylib"
if [[ -f "$testing_plugin" ]]; then
    swift test --disable-xctest -Xswiftc -load-plugin-library -Xswiftc "$testing_plugin" "$@"
else
    swift test --disable-xctest "$@"
fi
