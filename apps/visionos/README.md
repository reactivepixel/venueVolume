# Venue Volume for visionOS

A native SwiftUI + RealityKit prototype for placing virtual DMX fixtures in a mixed immersive space. Requires visionOS 2 or later; no external packages or backend are required.

See the [interface drawings](../../assets/design/venue-volume/visionos/README.md) for Figma layouts and editable SVGs of the cube, fixture controls, debug panel, placement flow, and launch window.

## Run

1. Open `VenueVolume.xcodeproj` in Xcode with the visionOS SDK installed.
2. Select the **VenueVolume** scheme and an Apple Vision Pro simulator or device.
3. For a physical headset, choose your signing team in Signing & Capabilities.
4. Run, select **Enter venue**, then use the floating debug panel.

For a ready-to-review simulator scene, select the shared **VenueVolume Demo** scheme. It passes `--demo`, opens the mixed immersive space automatically, and presents two sample fixtures with the 16-channel inspector expanded. Demo data only exists in Simulator memory; the normal **VenueVolume** scheme remains empty.

## Build screenshots

- [Launch window](Screenshots/venue-volume-launch.png)
- [Mixed-reality fixture scene](Screenshots/venue-volume-mixed-reality.png)

The checked-in Xcode project is ready to open. If changing project structure, regenerate it with `xcodegen generate` from this directory; `project.yml` is the source of truth.

## Interactions

- **Place fixture:** choose a distance from 0.75–4 meters. Look at a point on the translucent grid and pinch. A transparent, 24 cm cube stays at that point, with a name tooltip above it. Placement ends after each drop.
- **Select:** look at a cube and pinch to highlight it. Name labels also support single selection.
- **Configure:** double-select the name label to expand/collapse its floating panel. The debug panel's **Configure** button is an alternative. Only one inspector is open at a time.
- **Patch:** edit name, logical universe, one-based start address, and 1–16 channel count, then select **Apply patch**. Invalid ranges and overlapping footprints are rejected without changing the current patch. Reducing the channel count discards the removed values when applied.
- **Channels:** sliders update integer values immediately from 0–255. Each displays its channel number, absolute DMX address, and value. Scroll for all 16 channels; **Zero channels** clears the selected fixture's values.
- **Sync all configurations:** posts every fixture and channel through a local mock HTTP transport. Inspect **Last request** for the complete JSON. **Simulate API failure** tests HTTP 503 and retry. Changes made while syncing remain marked unsynced.
- **Debug panel:** continuously follows the wearer's head, offset to the right and below center. It remains present throughout the immersive session. **Leave** returns to the launch window.

visionOS does not expose raw eye gaze to apps. Placement uses Apple's system-targeted `SpatialTapGesture` on a visible surface, combined with ARKit device pose. This chooses the actual gaze-selected point on that surface, not a guess from head direction. There is no room mesh, plane detection, or physical-surface snapping. On a headset, the grid follows the head at the selected distance; placed cubes remain in world space.

In Simulator, ARKit device tracking is unavailable, so the placement grid uses a fixed pose at `(0, 1.5, 0)` facing negative Z. Use simulated gaze/click targeting on this grid. Simulator cannot validate real eye targeting, tracking recovery, or headset comfort.

## Mock API

`POST https://venue-volume.invalid/api/v1/dmx/configurations/sync`

An ephemeral `URLSession` uses a custom `URLProtocol` to intercept the request entirely in process. Nothing reaches the network. The request contains:

- `schemaVersion`, `requestID`, `createdAt`, and configuration `revision`
- `totalFixtures`, `totalChannels`
- `fixtures`: stable UUID, name, logical universe, start address, all channel values, and world position in meters

The mock returns HTTP 200 with accepted totals and the exact captured revision, or HTTP 503 when failure simulation is enabled. An empty fixture list is a valid complete snapshot. Only applied patches are sent; unsubmitted inspector fields remain drafts.

These are generic, unverified channel fixtures. This app does not load manufacturer profiles, translate protocol universe addresses, connect to the local bridge, or emit DMX/Art-Net/sACN. The logical universe range is 1–63999; each universe contains 512 slots.

## Project layout

- `VenueVolume/Spatial`: RealityKit scene, gaze-targeted placement, ARKit tracking, head attachment, and cube construction.
- `VenueVolume/Views`: launch window, name tooltip, fixture inspector, and debug/sync panel.
- `VenueVolume/Models`: observable session state and revision-aware syncing.
- `Core`: independently testable Swift package with fixture validation, patch allocation, and mock transport.

Configurations live in memory for the current app process. There are no persisted world anchors or cross-launch room restoration. Re-entering an immersive space may change the tracking origin; existing positions are session coordinates, not saved room locations.

## Verification

```sh
# From this directory
swift test --package-path Core
xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume \
  -destination 'generic/platform=visionOS Simulator' \
  -derivedDataPath /tmp/venue-volume-derived CODE_SIGNING_ALLOWED=NO build

# Also compile the real ARKit device path
xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume \
  -destination 'generic/platform=visionOS' \
  -derivedDataPath /tmp/venue-volume-device CODE_SIGNING_ALLOWED=NO build
```

Core tests cover footprint boundaries, overlaps, universe isolation, channel/value bounds, automatic patch allocation, full JSON round-trip, successful mock HTTP, empty snapshots, invalid-patch rejection, and failure/retry.

Verified on 2026-09-22 with Xcode 27.0: all 10 core tests passed, unsigned simulator and device builds succeeded with the visionOS 27 SDK, and demo mode rendered the cubes, labels, expanded inspector, and debug panel in the visionOS 27 simulator. Direct gaze/pinch behavior and headset comfort still require a physical Vision Pro.

Headset acceptance checklist:

1. Enter, place two fixtures at different gaze points, and move your head. Cubes should stay placed; debug should follow.
2. Single-select a cube; double-select its tooltip to open and close controls.
3. Set 16 channels, scroll to CH 16, change it to 255, and inspect the synced JSON.
4. Try an overflowing address and overlapping patch; both should leave the saved patch unchanged.
5. Start a sync and change a channel before it completes; the status should remain unsynced until the next sync.
6. Simulate API failure, disable simulation, and retry; verify HTTP 503 then HTTP 200.
7. Remove a fixture, sync, and confirm the totals decrease. Remove all and sync an empty snapshot.
8. Leave/re-enter, interrupt tracking, and verify controls recover without duplicate debug panels.

Reference APIs: [Apple's 2D/3D immersive attachments sample](https://developer.apple.com/documentation/realitykit/combining-2d-and-3d-views-in-an-immersive-app) and [device/head transform placement](https://developer.apple.com/documentation/visionos/placing-entities-using-head-and-device-transform).
