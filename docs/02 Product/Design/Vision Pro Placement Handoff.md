---
type: interaction-contract
status: implemented-local-navigation
updated: 2026-10-04
---

# Vision Pro placement handoff

## Capability and current limit

A link opened **on Vision Pro** can launch the installed Venue Volume app, open a known native Load Out and enter the placement tool for a selected fixture. A desktop web page cannot remotely launch an app on a separate headset. Copy the placement link and open it on that Vision Pro.

This change implements the URL contract, SaaS handoff UI and native receiver for **existing native saves with matching IDs**. It does **not** make newly created SaaS Load Outs available in the native app: preparation is still browser-local and there is no SaaS-to-native Load Out transfer service. The native room loader supports reviewed USDZ/mesh environments, not Movie2Splat PLY scans. The newly created SaaS Load Out therefore reports unavailable in the headset until a compatible import/sync path exists. This is not a platform restriction on deep linking.

Existing `.venuevolume` file import creates an independent saved setup with a new ID. Importing such a file does not automatically fulfill a SaaS link with the old ID. Do not match rooms, Load Outs or fixtures by their editable names.

## User flow

- In the Load Out inventory, **Place in Vision Pro** replaces **Set placement**.
- The handoff dialog names the Load Out and physical fixture. **Open on this Vision Pro** is an actual custom-scheme link; **Copy placement link** supports opening it on another device. It states the existing-native-save prerequisite and missing automatic transfer explicitly.
- The placement tab offers the same handoff action. Its separate numeric planning editor remains available.
- The app validates the link. If the same Load Out is already active, it keeps its unsaved edits and selects that existing fixture.
- If another saved Load Out must open, it resolves the exact saved UUID and fixture membership before changing rooms. Unsaved work offers Save, Discard or Cancel.
- After room assets load and spatial tracking is ready, the app selects that exact fixture and enters surface-placement mode. The user looks at a supported surface and pinches. Opening a link does not move, create, duplicate or patch a fixture.
- Invalid links, missing saves/fixtures, failed loads and cancelled system entry show a message. Manual room navigation cancels a pending placement so a delayed callback cannot select in the wrong venue.
- Browser placement state remains unchanged. Native placement results are not yet synchronized back to SaaS.

## URL contract

```text
venuevolume://place?version=1&loadout=<UUID>&fixture=<UUID>
```

Both UUIDs are canonical hyphenated identifiers. The receiver rejects duplicate or unknown query fields, unsupported versions/actions, invalid UUIDs, user info, ports, paths, fragments and overlong input. The URL carries navigation identifiers only: no file contents, credentials or arbitrary fetch URL.

`CFBundleURLTypes` registers `venuevolume`. All native windows receive URLs through `onOpenURL`, bring the launch window forward and share one pending navigation request. `FixturePlacementLink` defines the parser; `FixturePlacementHandoff` controls identity checks, unsaved-work handling and readiness. The existing reposition tool changes the selected unit, preserving its inventory identity and patch.

## Why a custom scheme now

Apple documents [custom URL schemes](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app) and SwiftUI's [onOpenURL](https://developer.apple.com/documentation/swiftui/view/onopenurl(perform:)). A custom scheme works without a hosted domain association. Universal links are preferable for a released SaaS service with browser fallback, but require a real owned HTTPS domain, Associated Domains entitlement and matching `apple-app-site-association` file. No production domain association was invented or deployed here.

## Verification and device check

Parser tests cover valid round trips and malformed/unexpected URLs. Native model smoke tests cover cold/warm handling, missing identities, dirty-work protection, readiness gating, cancellation, stale requests and no fixture duplication. Browser tests inspect the actual destination link and confirm the handoff does not modify Load Out state; desktop and mobile screenshots are captured.

Linux Swift testing cannot validate visionOS URL routing, SwiftUI presentation or RealityKit immersion. These still need a signed app build in Xcode and a simulator/headset check:

1. Install the new app version and create a saved native setup containing a fixture.
2. Use that setup's actual UUID and fixture UUID in the URL.
3. Open the URL in Vision Pro Safari (or use `xcrun simctl openurl booted '<url>'` in the visionOS simulator).
4. Verify cold launch, warm launch with the launch window closed, another dirty Load Out, missing IDs, cancelled immersion and unavailable tracking.
5. Verify the intended fixture is selected and awaits placement, with fixture count and patch unchanged.

An end-to-end test using a newly created SaaS Load Out remains blocked by the missing transfer service and native scan compatibility; passing navigation tests must not be reported as passing that end-to-end workflow.

Verified on 2026-10-04: 61 workspace browser checks, 23 Node model/link tests, 72 Swift core tests, the complete native model smoke suite (including the new handoff cases), frontend production build, Info.plist registration, and SwiftUI source syntax parsing passed. Swift tests ran in the existing Swift 6 container without network access. A visionOS SDK build, actual Safari-to-app delivery and on-device placement are **not verified** on this Linux host.
