#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
venue_test_build="$PWD/.build/session-tests"
mkdir -p "$venue_test_build"
venue_library_extension=dylib
if [[ "$(uname -s)" == Linux ]]; then venue_library_extension=so; fi
swiftc -swift-version 6 -parse-as-library -emit-library -emit-module -module-name VenueVolumeCore \
    Core/Sources/VenueVolumeCore/*.swift \
    -emit-module-path "$venue_test_build/VenueVolumeCore.swiftmodule" \
    -o "$venue_test_build/libVenueVolumeCore.$venue_library_extension"
swiftc -swift-version 6 -parse-as-library \
    -I "$venue_test_build" -L "$venue_test_build" -lVenueVolumeCore \
    -Xlinker -rpath -Xlinker "$venue_test_build" \
    VenueVolume/Models/*.swift Tests/SessionSmoke.swift Tests/AuditSmoke.swift Tests/InteractionSmoke.swift Tests/StartupSmoke.swift Tests/EditorPresentationSmoke.swift \
    -o "$venue_test_build/session-tests"
"$venue_test_build/session-tests"
