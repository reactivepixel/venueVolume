#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -z "${VV_SIMULATOR_ID:-}" ]]; then
  VV_SIMULATOR_ID="$(xcrun simctl list devices available --json | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next((v["udid"] for k,vs in d["devices"].items() if "visionOS" in k or "xrOS" in k for v in vs if v["state"]=="Booted"), ""))')"
fi
if [[ -z "$VV_SIMULATOR_ID" ]]; then
  echo "Boot an Apple Vision Pro Simulator in Xcode, then rerun."
  exit 1
fi
xcodebuild -project VenueVolume.xcodeproj -scheme 'VenueVolume Demo' \
  -destination "id=$VV_SIMULATOR_ID" -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
xcrun simctl install "$VV_SIMULATOR_ID" 'DerivedData/Build/Products/Debug-xrsimulator/Venue Volume.app'
xcrun simctl launch --terminate-running-process "$VV_SIMULATOR_ID" com.venuevolume.VenueVolume \
  --demo -ApplePersistenceIgnoreState YES "$@"
