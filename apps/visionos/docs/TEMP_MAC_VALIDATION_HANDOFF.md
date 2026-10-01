# Temporary Mac handoff: moving-head pilot

Status: Mac build and scripted Simulator validation passed on 2026-10-01; direct gesture and physical-device validation remain open. Keep this file until the Mac findings have been reviewed.

## Pickup

Pull the latest `origin/dev` on the Mac and read this file, the repository `AGENTS.md`, and `apps/visionos/README.md` before editing. The pilot implementation landed in `27ed5d6` (`v0.1.18`); this handoff note is being published in a later `dev` commit. Follow `AGENTS.md`: create one `agent/<task>` branch and `.worktree/<task>` from current `dev`, work and commit there, then have one integration owner merge into `dev`, bump both app package and lockfile patch versions, annotate the next unused tag, and push. Leave `master` untouched. Recheck remote `dev` before integrating so newer work is retained.

Use this file as the return channel. Replace `awaiting native validation` with the result and add a dated **Mac validation results** section containing commands, pass/fail outcomes, Xcode/visionOS versions, Simulator and device identifiers, screenshot or recording paths, code fixes, commit IDs, and unresolved gaps. Keep evidence under `apps/visionos/Screenshots/` if useful. Do not remove this temporary file until its results have been reviewed.

## What is implemented

- The app loads the bundled classroom and imports rooms. It also includes a Vision Pro ARKit mesh capture flow that needs live device validation. Simulator can replay a synthetic mesh but cannot perform live capture.
- The bundled CHAUVET Professional Rogue R1X Spot USDZ is the moving-head pilot. `FixtureRig` reparents `Head` under `Yoke`, animates pan/tilt, and attaches a shadow-casting `SpotLightComponent` at `Emitter`.
- The pilot is named in the toolbox, floating fixture label, Info panel, and position controls. Newly placed fixtures are dark until a preset is applied.
- The **Fixture position** tab has direct Pan/Tilt sliders in degrees. `VenueModel.setHeadAim` writes a per-fixture preview override, leaves the shared preset intact, persists the result, and groups slider movement for Undo/Redo. **Use preset aim** resets it. Room targeting still supports **Aim head (preview)** and **Aim mount**.
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

Fix any compiler, test, or runtime failures. If source files are added, regenerate the project from `project.yml` with `xcodegen generate` and review the generated project changes. Check that the new slider binding updates continuously and that its `onEditingChanged` transaction creates one Undo step for a gesture. The session smoke test and synthetic mesh room smoke include pilot aim checks, but they were added from Linux and have not been run with Xcode.

Boot a visionOS Simulator and launch `./scripts/run-demo.sh --blue --position-tab`. Inspect the actual 3D result and UI: the Rogue R1X model is visible, all pilot labels are legible, Pan rotates the yoke, Tilt rotates the head, and the lit beam follows the emitter. Drag each slider, confirm one Undo restores the prior pose and Redo restores the new pose; verify **Use preset aim**, head targeting, mount targeting, and persistence after leaving/re-entering the room. Check that another fixture sharing the preset does not change when this fixture's head is aimed.

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
