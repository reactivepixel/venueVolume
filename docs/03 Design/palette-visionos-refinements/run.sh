#!/bin/zsh
set -euo pipefail
proposal_root=${0:A:h}
proposal_sim=$(xcrun simctl list devices booted --json | python3 -c 'import json,sys; ds=json.load(sys.stdin)["devices"]; print(next(d["udid"] for r,vs in ds.items() if "visionOS" in r or "xrOS" in r for d in vs))')
xcodegen generate --spec "$proposal_root/project.yml"
xcodebuild -quiet -project "$proposal_root/PaletteRefinements.xcodeproj" -scheme PaletteRefinements -sdk xrsimulator -destination "platform=visionOS Simulator,id=$proposal_sim" -derivedDataPath "$proposal_root/DerivedData" build
xcrun simctl install "$proposal_sim" "$proposal_root/DerivedData/Build/Products/Debug-xrsimulator/PaletteRefinements.app"
xcrun simctl launch --terminate-running-process "$proposal_sim" com.venuevolume.PaletteRefinements --proposal "${1:-16}"
