# Left-hand viewer navigation — Mac validation, 2026-10-04

## Scope and source

Implemented on `agent/left-hand-navigation` in `.worktree/left-hand-navigation`, created from local `dev` at `80dee98` (`v0.2.6`). The branch includes the pending venue-exit fix (`f4ba9c1`) and fixture movement/controls update (`bddc763`) so the device build preserves both. No integration, version bump, tag or push was requested for this change; `master` was untouched. The installed app remains version **0.2.6**.

Left thumb/index pinch-and-drag translates the virtual viewpoint in all three dimensions, with no collision or room-boundary constraints. Left thumb/middle pinch-and-drag rotates the viewpoint: horizontal displacement controls yaw, vertical displacement controls pitch, and depth displacement controls roll. Releasing either pinch stops the change; another pinch starts a fresh drag. Double middle pinch resets orientation while keeping the current position. Double index pinch returns to spawn and resets orientation.

The app transforms the room root, including fixtures, colliders and lights, around the tracked viewer; it does not move ARKit's camera. Rotation pivots around the current tracked eye position. Fixture placements, preset values and DMX channels remain unchanged. The bottom controls stay attached to the physical head frame. Travel can pass through virtual walls and fixtures; passthrough and physical obstacles are unaffected.

The old left-hand-facing wrist activation is removed from the runtime. The Toolbox opens on venue entry and can be reopened from the bottom strip's **… → Toolbox** menu using right-hand input. That menu also provides six-direction 0.5 m steps, 15° rotation steps and Return to spawn for Simulator and hand-tracking fallback.

## Gesture and history details

- Translation gain: 3× hand displacement; rotation gain: 3 radians per metre. Drag dead zone: 15 mm.
- Pinch engagement: less than 25 mm; release: more than 40 mm. The selected fingertip must be at least 8 mm closer to the thumb than the other fingertip. Ambiguous relaxed hands do not start navigation or reserve UI input.
- A click must release within 300 ms without exceeding the drag threshold. Two clicks of the same finger within 400 ms reset. A drag or different finger breaks the click chain.
- Missing, invalid or stale tracking (over 250 ms) ends the action without a jump. Both fingers must be released before navigation can restart.
- One continuous drag is one Undo/Redo action. Virtual navigation is stored in the audit snapshot and resumes from active history. Older snapshots without `viewerPose` decode as default spawn. Opening a new venue or a named setup starts at spawn. Physical head/hand tracking and calibration are not time-traveled.
- Existing fixture gizmos and preset/retarget drafts remain available after navigation. Navigation does not change fixture or preset state.

Scene spatial events with explicit left chirality are consumed rather than routed into fixture editing. App window controls pause during left navigation, with early pinch reservation and a release cooldown. Unknown-chirality Simulator/accessibility input remains usable. Hand tracking recognizes navigation even while looking at empty space. Apple-owned window chrome and system gestures are outside the app's input routing. Physical arbitration over windows, attachments and system chrome still requires headset testing.

Implementation references: [Apple hand tracking](https://developer.apple.com/documentation/visionos/tracking-and-visualizing-hand-movement), [spatial-event chirality](https://developer.apple.com/documentation/swiftui/spatialeventcollection/event/chirality), and [spatial-event sample](https://developer.apple.com/documentation/visionos/petite-asteroids-building-a-volumetric-visionos-game). SDK interfaces and native compilation were used to confirm API availability.

## Environment

- Mac: Xcode **27.0 (27A266a)**, Swift **6.4 (swiftlang-6.4.0.34.1)**, visionOS SDK **27.0**.
- Simulator: Apple Vision Pro, visionOS **26.5**, UDID `288D6CFE-09D9-422B-96A0-53081DA29C44`.
- Chris's Vision Pro: paired, Developer Mode enabled, visionOS **27.0.1 (24M372)**, destination `00008112-001619923CC1A01E`.
- The Mac was locked during native UI inspection. Device lock-state inspection returned `passcodeRequired: true`, `unlockedSinceBoot: true`.

## Commands and outcomes

Commands below ran from `apps/visionos` in the assigned worktree. Final source was built for both targets and installed after the last implementation fixes.

```sh
swift test --package-path Core
./scripts/test-session.sh
python3 Tests/verify-assets.py
```

**Passed:** 98 Core tests, eleven session groups, and asset validation for all 252 bundled fixture models plus room, rig, mapped-room and fortress contracts. Seven focused Core tests cover gesture translation, rotation, resets, click discrimination, loss recovery, ambiguous/invalid input and pose validation. Model coverage includes atomic navigation history, fixture/preset isolation, preserved gizmo context, persistence, legacy audit decoding and fallback controls.

```sh
xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume -configuration Debug \
  -destination 'platform=visionOS Simulator,id=288D6CFE-09D9-422B-96A0-53081DA29C44' \
  -derivedDataPath .build/navigation-simulator CODE_SIGNING_ALLOWED=NO build

xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume -configuration Debug \
  -destination 'platform=visionOS,id=00008112-001619923CC1A01E' \
  -derivedDataPath .build/chris-device DEVELOPMENT_TEAM=3M53U7Y396 build
```

**Both builds passed.** Signing was overridden only on the command line; the primary checkout's owner signing changes were not modified.

```sh
xcrun simctl install 288D6CFE-09D9-422B-96A0-53081DA29C44 \
  '.build/navigation-simulator/Build/Products/Debug-xrsimulator/Venue Volume.app'
xcrun simctl launch --terminate-running-process --console-pty \
  288D6CFE-09D9-422B-96A0-53081DA29C44 com.venuevolume.VenueVolume \
  --demo --input-smoke --movement-smoke --navigation-smoke -ApplePersistenceIgnoreState YES
```

The Simulator launch emitted all four pass markers. A second launch using the same arguments plus `--venue-exit-smoke` emitted all five:

```text
TOOLBOX_WINDOW_SMOKE_PASS
SPATIAL_INPUT_SMOKE_PASS
FIXTURE_MOVEMENT_SMOKE_PASS secondClick=true bodySlide=true floorHit=true wallNormal=true undoRedo=true horizontalDock=true
VIEWER_NAVIGATION_SMOKE_PASS freeTravel=true fixedFixtures=true rotationPivot=true doubleMiddle=true doubleIndex=true undoRedo=true release=true
VENUE_EXIT_SMOKE_PASS immersed=false toolboxWindows=0 pendingRecall=false
```

The native navigation smoke supplies synthetic joint positions to the renderer's actual navigation adapter, moves beyond room boundaries, inspects the viewer position in RealityKit coordinates, rotates without changing that position, verifies fixture/preset isolation, Undo/Redo, both resets and input release. It does **not** synthesize actual SwiftUI spatial events or ARKit hand tracking. The exit check confirms the open Toolbox closes when leaving the venue.

```sh
xcrun simctl io 288D6CFE-09D9-422B-96A0-53081DA29C44 screenshot \
  docs/validation/evidence/2026-10-04-left-hand-navigation/navigation-spawn.png
```

The [Simulator screenshot](evidence/2026-10-04-left-hand-navigation/navigation-spawn.png) was inspected after navigation returned to spawn. It records window/layout state, not physical gesture or motion acceptance.

```sh
xcrun devicectl device install app --device 00008112-001619923CC1A01E --timeout 45 \
  '.build/chris-device/Build/Products/Debug-xros/Venue Volume.app'
xcrun devicectl device process launch --device 00008112-001619923CC1A01E \
  --timeout 45 --terminate-existing com.venuevolume.VenueVolume
xcrun devicectl device info lockState --device 00008112-001619923CC1A01E --timeout 15
xcrun devicectl device info details --device 00008112-001619923CC1A01E --timeout 15
```

**Final signed app installed successfully** on Chris's Vision Pro (installation database sequence 1096; bundle version 0.2.6). The remote launch attempt on the preceding corrected build timed out after 45 seconds; the headset required a passcode. The final source was then rebuilt and installed, but its launch is **unconfirmed**. No demo, persistence-reset or synthetic smoke flags were sent to the headset.

## Repairs made during validation

1. Fixed a native runtime crash caused by reading `VenueModel` from an environment unavailable at an outer input modifier. The modifier now receives the model explicitly on every window and attachment.
2. Corrected the native smoke setup to release the synthetic hand after room-load cancellation before starting a pinch, matching the recognizer's deliberate release-to-rearm behavior.
3. Preserved fixture manipulation and preset target/draft context while navigating. Added focused model coverage for preserved gizmo state.
4. Prevented ambiguous relaxed finger positions from reserving app UI input. Avoided redundant idle pose, input-reservation and root-transform writes.

No failures remained in the final automated checks or either final build.

## Remaining acceptance

**Not tested on the headset:** worn-device launch, actual left index/middle recognition, right/left input arbitration over app controls and window chrome, tracking permission prompts and tracking-loss recovery in real lighting, motion comfort, sustained performance, and live scanned-room navigation/fixture placement. Simulator mouse UI exploration was also unavailable while the Mac was locked. These gaps are not established by compilation, synthetic joint input or the screenshot.

Evidence is retained under [the navigation evidence directory](evidence/2026-10-04-left-hand-navigation): Core/session/asset results, final native runtime and exit markers, device install/launch/lock results, and compressed full build logs. The earlier crash and pre-arming smoke failure logs are retained as resolved validation evidence.
