# Viewer-origin preset connector — 2026-10-04

## Interaction and visual direction

Reference inspected in the browser: [Omer Assa's connector video](https://x.com/omer_assa/status/2106758938926391416). The visible cues used here are a restrained curved white cable, a warm highlighted connection point, a circular endpoint and a short settling movement. The reference's persistent colored node connections are not copied into the venue: this connector exists only during an active preset application.

Visual thesis: a light, curved white guide with one warm snap accent, readable against the venue without window-to-object wiring. The workspace remains dominant; the lower pane carries the active preset, candidate and completion/cancellation controls. Motion is limited to a short endpoint ease and a single small settling ripple/ring response. Reduce Motion removes that movement.

Workflow:

1. In Presets, select the connector button beside a preset (**Apply in venue**).
2. A dotted curved guide starts at the tracked right hand. Without tracked hand input, it starts below/right of the viewer. No list-row position or window transform is read or rendered.
3. Aim toward a fixture. Before a pinch, the guide uses head direction; this is not eye tracking. Right-hand spatial input supplies the precise pointer/ray during a pinch. Holding and moving updates the candidate. A solid cable, warm ring and thin fixture outline indicate a snap.
4. Release on a valid fixture to apply once, or use **Apply to fixture** in the lower pane. A missed release leaves Apply active. **Cancel** in that pane clears the interaction without changing fixture values or history.
5. Closing/repositioning Toolbox does not remove or reanchor Apply. Success clears the cable and briefly highlights the fixture white; failure uses red. The lower pane displays textual success/error feedback. A new activation replaces the previous active preset. Left-hand navigation, leaving the venue, backgrounding and invalid scene/preset state cancel application.

The endpoint is moved to the nearest fixture-bounds surface, slightly toward the user, so the ring is not buried inside the fixture body. Existing snap hysteresis, actual fixture bounds, wall occlusion checks, preset isolation and single-action Undo/Redo remain in use. The direct preset Apply menu is retained as an alternative.

## Source and integration

Worktree: `.worktree/preset-tether`, branch `agent/preset-tether`, created from local `dev` at `80dee98`. It includes `c812024` and its prerequisite venue-exit/fixture movement changes. Remote `origin/dev` at `9e0bb15` contains the independent offline cue-player design; the integration preserves both branches. Local and remote history had independently used `v0.2.6`; existing tags are not rewritten. The next unused integration tag is `v0.2.7`.

## Checks

Environment: Xcode 27.0 (27A266a), Swift 6.4, visionOS SDK 27.0. Native execution used the Apple Vision Pro Simulator on visionOS 26.5, UDID `288D6CFE-09D9-422B-96A0-53081DA29C44`.

Commands ran from `apps/visionos` in the assigned worktree:

```sh
swift test --package-path Core
./scripts/test-session.sh
python3 Tests/verify-assets.py
xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume -configuration Debug \
  -destination 'platform=visionOS Simulator,id=288D6CFE-09D9-422B-96A0-53081DA29C44' \
  -derivedDataPath .build/tether-simulator CODE_SIGNING_ALLOWED=NO build
xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume -configuration Debug \
  -destination 'generic/platform=visionOS' \
  -derivedDataPath .build/tether-device CODE_SIGNING_ALLOWED=NO build
```

Passed: **99 Core tests**, **12 session groups**, asset contracts for **252 fixture models**, Simulator build and generic visionOS device build. Focused coverage verifies activation without geometry, missed-release persistence, Cancel without mutation, stale/superseded input, single application, success/error feedback, Toolbox independence, left-hand navigation cancellation, and Undo/Redo.

```sh
xcrun simctl install 288D6CFE-09D9-422B-96A0-53081DA29C44 \
  '.build/tether-simulator/Build/Products/Debug-xrsimulator/Venue Volume.app'
xcrun simctl launch --terminate-running-process --console-pty \
  288D6CFE-09D9-422B-96A0-53081DA29C44 com.venuevolume.VenueVolume \
  --demo --preset-drag-smoke --input-smoke --navigation-smoke --venue-exit-smoke \
  -ApplePersistenceIgnoreState YES
```

The preset smoke supplies synthetic world-space pointer/hand samples through the real snap/render/commit path. It asserts no idle tether, the exact user-side origin, dotted/solid states, actual Toolbox-window dismissal without ending Apply, missed-release persistence, one application/history step, feedback, Cancel, Undo and Redo. It does not synthesize physical hand tracking or OS spatial events.

```text
PRESET_DRAG_SMOKE_DOTTED viewerOrigin=true rowIndependent=true
PRESET_DRAG_SMOKE_SOLID curved=true targetRing=true
PRESET_DRAG_SMOKE_PASS viewerOrigin=true noRowGeometry=true toolboxClose=true missedReleaseStaysActive=true applyOnce=true cancel=true undo=true redo=true syntheticPointer=true
TOOLBOX_WINDOW_SMOKE_PASS
SPATIAL_INPUT_SMOKE_PASS
VIEWER_NAVIGATION_SMOKE_PASS freeTravel=true fixedFixtures=true rotationPivot=true doubleMiddle=true doubleIndex=true undoRedo=true release=true
VENUE_EXIT_SMOKE_PASS immersed=false toolboxWindows=0 pendingRecall=false
```

Screenshots were captured at the dotted and solid markers using:

```sh
xcrun simctl io 288D6CFE-09D9-422B-96A0-53081DA29C44 screenshot \
  docs/validation/evidence/2026-10-04-preset-tether/dotted.png
xcrun simctl io 288D6CFE-09D9-422B-96A0-53081DA29C44 screenshot \
  docs/validation/evidence/2026-10-04-preset-tether/snapped.png
```

Both screenshots were visually inspected. [Dotted guide with Toolbox open](evidence/2026-10-04-preset-tether/dotted.png); [solid connection after Toolbox closes](evidence/2026-10-04-preset-tether/snapped.png). The captures are pre-release validation frames; the release bump is checked separately. Logs and compressed build output are retained in the same evidence directory.

## Remaining validation

The Mac was locked during native UI access. Mouse/physical pinch exploration, right-hand tracking, eye/hand arbitration across app windows, real-world comfort and headset performance are **not tested** in this change. The generic device build is compilation evidence, not a headset install or run. Precise release coordinates, warm ring visibility across all fixture shapes and bright-room contrast still need worn-device acceptance. No hardware deployment was requested in this turn.

## Integration release check

The remote merge added the cue-player research/hardware files without application-source conflicts. Both npm app package and lockfile versions, `project.yml` and generated Xcode settings were bumped to **0.2.7** in the integration merge. The version-only Simulator rebuild passed using the command above; the built bundle's `CFBundleShortVersionString` is **0.2.7**. The only build warning was skipped App Intents metadata extraction because this app has no AppIntents framework dependency.

The integration commit is tagged with an annotated `v0.2.7`; `python3 apps/visionos/scripts/check-version.py --release` checks the tag, both npm apps, generated settings and Info.plist binding. Existing tags are retained. This request integrates local `dev`; no push was requested.
