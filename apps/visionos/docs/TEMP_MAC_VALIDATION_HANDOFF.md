# Temporary Mac handoff: moving-head pilot

Status: Mac build and scripted Simulator validation passed on 2026-10-01; direct gesture and physical-device validation remain open. Keep this file until the Mac findings have been reviewed.

## Pickup

Pull the latest `origin/dev` on the Mac and read this file, the repository `AGENTS.md`, and `apps/visionos/README.md` before editing. The pilot implementation landed in `27ed5d6` (`v0.1.18`); this handoff note is being published in a later `dev` commit. Follow `AGENTS.md`: create one `agent/<task>` branch and `.worktree/<task>` from current `dev`, work and commit there, then have one integration owner merge into `dev`, bump both app package and lockfile patch versions, annotate the next unused tag, and push. Leave `master` untouched. Recheck remote `dev` before integrating so newer work is retained.

Use this file as the return channel. Replace `awaiting native validation` with the result and add a dated **Mac validation results** section containing commands, pass/fail outcomes, Xcode/visionOS versions, Simulator and device identifiers, screenshot or recording paths, code fixes, commit IDs, and unresolved gaps. Keep evidence under `apps/visionos/Screenshots/` if useful. Do not remove this temporary file until its results have been reviewed.

## What is implemented

- The app loads the bundled classroom and imports rooms. It also includes a Vision Pro ARKit mesh capture flow that needs live device validation. Simulator can replay a synthetic mesh but cannot perform live capture.
- The bundled CHAUVET Professional Rogue R1X Spot USDZ is the moving-head pilot. `FixtureRig` reparents `Head` under `Yoke`, animates pan/tilt, and attaches a shadow-casting `SpotLightComponent` at `Emitter`.
- The pilot is named in the toolbox, floating fixture label, Info panel, and position controls. Newly placed fixtures are dark until a preset is applied.
- The current interaction update replaces direct fixture sliders with colored 3D rotation rings and translation handles. DMX sliders remain in the preset editor. Room targeting supports held preview adjustments and explicit Save/Cancel; saving writes a per-fixture aim override while leaving its shared preset intact. **Use preset aim** resets it. The wrist shows scene items or selected-item information, with a separate full item editor that follows selection.
- `VV Preview 16` is a synthetic visualizer profile, not CHAUVET's DMX personality or calibrated photometry. Pilot travel is roughly 270° pan / 120° tilt; the physical product is specified for up to 540° / 250°. No live fixture output is implemented.

The asset record is `assets/fixtures/chauvet-professional/rogue-r1x-spot/fixture.json`. The app bundles the matching `FixtureAssets/RogueR1X/fixture.usdz` and metadata. The record remains `researched` because its dimensional axis assignment and some pivot detail are estimated. The manufacturer source is <https://chauvetprofessional.com/product/rogue-r1x-spot/>.

## Required Mac verification and repairs

From `apps/visionos` in your assigned worktree:

```sh
swift test --package-path Core
./scripts/test-session.sh
python3 Tests/verify-assets.py
xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume \
  -destination 'generic/platform=visionOS Simulator' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume \
  -destination 'generic/platform=visionOS' \
  -derivedDataPath DerivedData-device CODE_SIGNING_ALLOWED=NO build
```

Fix any compiler, test, or runtime failures. If source files are added, regenerate the project from `project.yml` with `xcodegen generate` and review the generated project changes. Check that each ring/arrow drag updates continuously and creates one Undo step. Verify the native held retarget gesture stages a preview without saving; release leaves Save/Cancel open. Model and synthetic-room command checks pass on the Mac; direct gestures remain open as described below.

Boot a visionOS Simulator and launch `./scripts/run-demo.sh --blue --position-tab`. Inspect the actual 3D result and UI: the Rogue R1X model is visible, all pilot labels are legible, preset Pan rotates the yoke, preset Tilt rotates the head, and the lit beam follows the emitter. Verify scene-list clearing, item selection switching, full-editor pop-out and background deselection. Drag each colored axis handle/ring, confirm one Undo restores the prior pose and Redo restores the new pose; verify **Use preset aim**, head targeting, mount targeting, and persistence after leaving/re-entering the room. Check that another fixture sharing the preset does not change when this fixture's head is aimed.

Run `./scripts/run-demo.sh --blue --library-smoke` and `./scripts/run-demo.sh --blue --history-smoke` against the synthetic mesh room. Verify the pilot places and aims there, saved setups reopen with the same pose, and history restores the pose. Inspect fixture selection, collision targets, lighting, and shadows for the classroom and synthetic scan replay.

If a development Vision Pro is connected, test a real scan with World Sensing permission, save/open it, place and aim the pilot on a scanned horizontal surface, save a setup, and reopen it. Record device behavior, tracking, frame time/comfort, and any failures. If no headset is available, mark live capture and device behavior **not tested**; a Simulator pass does not establish them.

## Acceptance report

Before handoff completion, report which paths passed: Core/session tests, Simulator build, unsigned device build, Simulator interaction, synthetic mesh replay, and physical headset scan. Include exact failures and fixes. Update this file with that report, commit it with any code changes on the Mac worktree, integrate under `AGENTS.md`, and push `dev` plus the required annotated patch tag.

## Mac validation results — 2026-10-01

**Host and source.** Xcode 27.0 (27A266a); visionOS SDK and booted Simulator runtime 27.0. Simulator: Apple Vision Pro `37FB51A4-DFF5-40C0-BFE1-32F8AA69EE4F`. `xcrun devicectl list devices` listed only simulated devices, so there was no development Vision Pro available. In the primary checkout, `git fetch origin dev --tags` and `git merge --ff-only origin/dev` placed `dev` at `251e1cc` (`v0.1.20`); `git tag --points-at a7c93f4` confirmed `v0.1.19` is included in its ancestry. Work ran on `agent/moving-head-native-validation` in `.worktree/moving-head-native-validation`. The code and screenshots commit is `f593210`.

**Exact checks from `apps/visionos` in that worktree.**

| Command | Outcome |
| --- | --- |
| `swift test --package-path Core` | PASS: 38 tests in one suite. |
| `./scripts/test-session.sh` | PASS: session, room session and audit checks, including fixture targeting, preset isolation, persistence, and history. New coverage places two pilot fixtures on one preset, changes one through multiple Pan updates, and confirms one Undo/Redo restores only that fixture. |
| `python3 Tests/verify-assets.py` | PASS: exact room and fixture copies, SHA-256, articulation and emitter metadata. |
| `xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume -destination 'generic/platform=visionOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build` | BUILD SUCCEEDED after repairs. |
| `xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume -destination 'generic/platform=visionOS' -derivedDataPath DerivedData-device CODE_SIGNING_ALLOWED=NO build` | BUILD SUCCEEDED after repairs; unsigned compile only, no device install. |
| `./scripts/run-demo.sh --blue --position-tab` | BUILD SUCCEEDED; installed/launched on the Simulator. Pilot fixture, floating label, blue wall pool, toolbox, and the **Fixture position** window with Rogue R1X name and Pan/Tilt controls were visible. |
| `./scripts/run-demo.sh --blue --library-smoke` | BUILD SUCCEEDED and launched. Its synthetic-room path was also exercised by the history smoke below. |
| `./scripts/run-demo.sh --blue --history-smoke` | BUILD SUCCEEDED and launched. Relaunching that build with `xcrun simctl launch --console-pty --terminate-running-process 37FB51A4-DFF5-40C0-BFE1-32F8AA69EE4F com.venuevolume.VenueVolume --demo -ApplePersistenceIgnoreState YES --blue --history-smoke` printed `ROOM_LIBRARY_SMOKE_PASS` and `AUDIT_HISTORY_SMOKE_PASS`. |

The runtime smoke now verifies synthetic mesh placement and aim, saving/reopening the mesh setup with the exact pilot pose, a grouped aim Undo/Redo in that room, and return to the saved classroom. The history screenshot shows the audit events and restored classroom fixture. Scripted `simctl launch --terminate-running-process` states for `--blue --aim-left`, `--blue --retarget-head`, `--blue --retarget-mount`, and `--blue --show-info` were captured after load. Compared with the baseline, Pan visibly rotates the yoke and moves the blue pool left; head targeting moves the head and pool toward the chosen point; mount targeting rotates the base while model tests confirm DMX values are preserved. The fixture Info label shows the catalog and channels. Classroom lighting is visible; shadow quality was not conclusively assessed.

**Evidence** (all under `apps/visionos/Screenshots/`): `2026-10-01-pilot-position.png` (fixture control window and Pan/Tilt), `2026-10-01-pilot-info.png` (expanded label), `2026-10-01-pilot-pan.png` (changed yoke and blue pool), `2026-10-01-target-head.png`, `2026-10-01-target-mount.png`, `2026-10-01-synthetic-room.png` (synthetic scan replay), and `2026-10-01-history-smoke.png` (audit result and restored classroom). Captured with `xcrun simctl io 37FB51A4-DFF5-40C0-BFE1-32F8AA69EE4F screenshot Screenshots/<name>.png`. No recording was made.

**Repairs.** `FixturePlacementView` now reads the selected fixture's current channels in the Pan/Tilt binding getter, so a drag does not rely on a value captured when SwiftUI last drew the view. `VenueSpaceView` now opens the fixture control window for the documented `--position-tab` demo flag. `SessionSmoke` covers continuous Pan updates, grouped Undo/Redo, and shared-preset isolation. `RoomLibrarySmoke` covers exact saved mesh pose and mesh-room aim history. Both final native builds passed after these edits.

**Open validation.** The Mac remained locked and the native app-control surface could not unlock it. Thus actual Simulator slider dragging, gaze/pinch placement and targeting, drag-and-drop, **Use preset aim** button activation, collision-target tapping, and visual review of intermediate animation frames are **not tested by direct interaction**. The model/session/runtime smoke paths for those behaviors pass, but they are not substitutes for gesture validation. A live ARKit room scan, World Sensing permission, scanned-surface placement, device persistence, tracking, frame time, and wearer comfort are **not tested** because no physical Vision Pro was connected. `VV Preview 16` remains a visualizer profile, not manufacturer DMX or live output.

## Mac validation results — 2026-10-01, fixture interaction feedback

**Source and host.** Work started from current `dev` / `origin/dev` `bda9e09` (`v0.1.21`) in `agent/fixture-interaction`, created with `git worktree add -b agent/fixture-interaction .worktree/fixture-interaction dev`. All edits and tests ran in that worktree. SSH fetch failed with `Permission denied (publickey)`; `git -c credential.helper='!gh auth git-credential' fetch https://github.com/reactivepixel/venueVolume.git dev:refs/remotes/origin/dev --tags` succeeded using the existing GitHub CLI login. Code, regressions and screenshots are committed as `69f6567`. This feedback branch is retained for review; it has not been integrated or released. `master` was untouched.

Xcode 27.0 (27A266a), visionOS SDK 27.0 and Simulator runtime 27.0 (24M362). Booted Simulator: Apple Vision Pro `37FB51A4-DFF5-40C0-BFE1-32F8AA69EE4F`. `xcrun devicectl list devices` now lists **Chris’s Apple Vision Pro**, physical UDID `00008112-001619923CC1A01E`, connected. It was not installed to or worn for this validation; the device OS version was not established.

**Implemented and repaired.** The palm Recent column is replaced by scene items, patch/preset summaries, individual delete controls, Clear all and an empty-scene guide. Selection replaces it with item information and a pop-out editor. The editor reads the current selected ID, validates editable name/universe/address, and closes on deselection. Room/background hit targets clear selection. Preset management remains a separate window; its old Fixture position tab was removed. Mount transformations use colored 3D rotation rings and translation arrows, preserving DMX and grouping each drag into one Undo step. Held targeting stages head/mount previews without persisting or journaling; release leaves Save/Cancel open. Saving re-solves against current preset values, preventing an older preview from overwriting a concurrently saved preset. Switching selection discards the pending target. Interrupted axis drags finish their transaction and cannot continue on a newly selected fixture.

During repeated relaunches, a restored item window appeared without the launcher or venue. The full editor now exposes `VenueEntryButton` while outside the venue and avoids dismissing itself before entry; demo runs can resume from it and dismiss unrequested restored item windows. Subsequent launches rendered the room and target dialog correctly. The item editor and targeting screenshots below show the repaired runtime states.

**Commands and outcomes** (from `apps/visionos` in the assigned worktree):

| Command | Outcome |
| --- | --- |
| `swift test --package-path Core` | PASS: 39 tests; new room-axis quaternion composition and angle-wrap coverage. |
| `./scripts/test-session.sh` | PASS: session, room session, audit and new interaction smoke checks. Covers target Save/Cancel and repeated held updates, no unsaved persistence/history, current-preset preservation, selection changes, validated patch edits, axis-only translation, mount rotation with unchanged DMX, bounds rejection, one-step Undo/Redo, and Clear all restoration. |
| `python3 Tests/verify-assets.py` | PASS: exact room/fixture copies, SHA-256 and articulation/emitter metadata. |
| `xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume -destination 'generic/platform=visionOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build` | BUILD SUCCEEDED. |
| `xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume -destination 'generic/platform=visionOS' -derivedDataPath DerivedData-device CODE_SIGNING_ALLOWED=NO build` | BUILD SUCCEEDED; unsigned compile, not installation. |
| `./scripts/run-demo.sh --blue --scene-overview` | Built, installed and launched; native scene breakdown render inspected. |
| `./scripts/run-demo.sh --blue --transform-gizmo` | Built, installed and launched; colored rings and transform mode dialog visible. |
| `./scripts/run-demo.sh --blue --retarget-head` | Built, installed and launched; cyan pending target, changed head/blue light pool and enabled Save/Cancel dialog visible after room loading. |
| `xcrun simctl launch --terminate-running-process 37FB51A4-DFF5-40C0-BFE1-32F8AA69EE4F com.venuevolume.VenueVolume --demo -ApplePersistenceIgnoreState YES --blue --position-tab` | Pop-out Transform editor and rings rendered; no fixture transform or Pan/Tilt sliders. |
| `xcrun simctl launch --terminate-running-process 37FB51A4-DFF5-40C0-BFE1-32F8AA69EE4F com.venuevolume.VenueVolume --demo -ApplePersistenceIgnoreState YES --blue --show-item-editor` | Full Info/patch editor rendered alongside the selected wrist pane. |
| `xcrun simctl launch --console-pty --terminate-running-process 37FB51A4-DFF5-40C0-BFE1-32F8AA69EE4F com.venuevolume.VenueVolume --demo -ApplePersistenceIgnoreState YES --blue --history-smoke` | PASS: console printed `ROOM_LIBRARY_SMOKE_PASS` and `AUDIT_HISTORY_SMOKE_PASS`. Updated native smoke places a pilot on a synthetic mesh, previews/saves a target, reloads its saved pose, rotates with an axis command while preserving DMX, verifies Undo/Redo and returns to the classroom. |
| `python3 scripts/check-version.py` | PASS: existing v0.1.21 agrees with both npm apps and visionOS bundle/build settings. No release version bump on this review branch. |
| `git diff --check` | PASS. |

Project regeneration used `xcodegen generate`, then `perl -pi -e 's/BuildableName = "VenueVolume\.app"/BuildableName = "Venue Volume.app"/g' 'VenueVolume.xcodeproj/xcshareddata/xcschemes/VenueVolume Demo.xcscheme' VenueVolume.xcodeproj/xcshareddata/xcschemes/VenueVolume.xcscheme`. Both added Swift files are present in the generated project. Builds emitted only the routine AppIntents metadata warning for the app with no AppIntents dependency.

**Evidence.** Captured with `xcrun simctl io 37FB51A4-DFF5-40C0-BFE1-32F8AA69EE4F screenshot Screenshots/<name>.png`, inspected visually:

- [Scene breakdown](../Screenshots/interaction-scene-overview.png)
- [Selected wrist item pane](../Screenshots/interaction-selected-item.png)
- [Colored rotation rings](../Screenshots/interaction-axis-rings.png)
- [Target preview with Save/Cancel](../Screenshots/interaction-target-preview.png)
- [Pop-out Transform editor](../Screenshots/interaction-item-editor.png)
- [Full Info/patch editor](../Screenshots/interaction-full-item-editor.png)
- [Native history smoke result](../Screenshots/interaction-history-smoke.png)

These are seeded native presentation states and real model/renderer command checks. They do not simulate a user's pinch or mouse gesture. No recording was made.

**Remaining validation.** The user unlocked the Mac, but the native-control tool repeatedly timed out reading Xcode 27 Device Hub (`Computer Use server error -10005: timeoutReached`). Thus actual background tapping, selection/context switching through UI clicks, Clear all confirmation, held pinch/drag retargeting, ring/arrow dragging, preset drops and editor button activation are **not tested by direct interaction**. Model regressions pass for their state transitions. Although a physical Vision Pro is connected, signed device deployment, live World Sensing capture, scan save/reopen, scanned-surface gestures, palm reveal/following, held-hand target motion, spatial alignment, tracking, comfort and performance are **not tested**. These remain headset acceptance work; synthetic mesh replay is not live capture evidence.
