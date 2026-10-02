#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
venue_test_build="$PWD/.build/session-tests"
mkdir -p "$venue_test_build"
swiftc -swift-version 6 -parse-as-library -emit-library -emit-module -module-name VenueVolumeCore \
    Core/Sources/VenueVolumeCore/*.swift \
    -emit-module-path "$venue_test_build/VenueVolumeCore.swiftmodule" \
    -o "$venue_test_build/libVenueVolumeCore.dylib"
swiftc -swift-version 6 -parse-as-library \
    -I "$venue_test_build" -L "$venue_test_build" -lVenueVolumeCore \
    -Xlinker -rpath -Xlinker "$venue_test_build" \
    VenueVolume/Models/VenueModel.swift Tests/SessionSmoke.swift Tests/AuditSmoke.swift Tests/InteractionSmoke.swift \
    -o "$venue_test_build/session-tests"
"$venue_test_build/session-tests"
