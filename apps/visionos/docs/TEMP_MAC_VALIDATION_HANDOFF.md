# Temporary Mac handoff: expanded catalog validation

Status: Catalog rollout awaits native validation. The earlier pilot and interaction results are preserved below; they do not validate the new catalog integration.

## Current pickup — legacy lighting and effects expansion, 2026-10-02

Pull current `dev` and follow `AGENTS.md` in a fresh worktree. Current totals are **252 packaged models, 175 articulated models and 322 preview joints**. The complete CSV has **323 rows from 52 manufacturers**. This batch adds 64 rows and 32 models to the previous 220-model release; 32 new research-only rows remain blocked. The canonical per-item explanations are in `assets/fixtures/research/show-equipment-catalog.csv`, column `pipelineErrors`.

Run the Core suite (45 tests passed on Linux), session checks, bundle verifier, both unsigned Xcode builds and the catalog smoke below. Expect `CATALOG_SMOKE_PASS assets=252`; record actual native results rather than inheriting the pilot pass. Recheck the room scanning/placement/targeting workflows without altering the newer Fortress reference project.

Prioritize these new mechanisms in Simulator and on headset:

- Antari B-200: six visible wheels rotate around the shared axle; manual bracket tilt carries the rotating assembly while the support stays fixed. No particles or light appear.
- Antari Z-1200III, S-100X, S-200X and SW-250: manual bracket tilt, never a claim that the real machine is motorized.
- ADJ X-Move Laser: two motor-preview joints but zero ordinary light emitters; head targeting is intentionally unavailable. No laser ray or firing controls are implemented.
- Scorpion Dual RGB: manual bracket tilt; no light emitter or simulated scanning pattern.
- Robe ColorSpot/ColorWash AT and MAC 2000: pan/tilt with optics attached; old-model source dimensions remain documented with pose caveats.
- SHOWVEN SPARKULAR variants, MDG, Look Solutions and Le Maitre: stable placed equipment with no unintended spotlight output.

Nine packaged models remain `visual_review_pending`, including seven in this batch: F-1, HZ-1000, Entour Venue, G300, GForce 3, MAC 2000 Profile and MAC 2000 Wash. The two previous ETC/Astera findings remain. See both `research/fixtures/expansion-v*/visual-review-issues.json` registries and the independent atmosphere QA report. A RealityKit import pass does not resolve these source/shape findings. All 252 assets still await native validation for this release; 243 have no additional local visual flag.

Append dated Xcode/visionOS/device results and evidence to this file. Update `native_validation` only for tested assets and republish pipeline status. Keep synthetic VV Preview 16 separate from manufacturer DMX, ILDA, external/manual control and safety-critical effect control. Retain the historical handoff below.

## Previous pickup — touring, mid-market and DJ expansion, 2026-10-02

Pull the latest `dev` and follow `AGENTS.md` in a fresh assigned worktree. The expanded release packages **220 models, 162 articulated assets and 302 preview joints**, including 93 new models. The complete CSV has 259 items from 47 manufacturers; 39 research-only items intentionally have no model. Read `assets/fixtures/research/pipeline-status.json` for the authoritative current totals and each row's `pipelineErrors`.

Run the Core tests, `./scripts/test-session.sh`, `python3 Tests/verify-assets.py`, and both unsigned Xcode builds listed below. Run `./scripts/run-demo.sh --catalog-smoke`; require the native catalog smoke to import every packaged model and verify every joint member path. Record the actual count and log marker, not the older 127-model expectation. Then test room placement, mount targeting, per-instance joint overrides, save/reopen and Undo/Redo on representative models:

- CHAUVET DJ Intimidator Spot Duo: independently move pan/tilt for each of the two heads. Both emitters must follow their own head; one head's control must not move the other. Single-head target solving is intentionally unavailable for this compound model.
- Eurolite KLS-120: four manually aimable cans below a fixed crossbar, each with a matching emitter. The controls must say manual, not imply physical motors.
- Claypaky Volero Cube, Martin MAC Aura Raven XIP and MAC One Beam: verify custom optics survive RealityKit import and the yoke/head rotate without detached lens meshes.
- Chroma-Q Color Force 3 72 and ACME LIGHTNING: bracket tilt moves the housing/optics while supports remain fixed.
- ETC ColorSource PAR jr / Spot jr and Astera AX5: verify the revised visible optics and manual mounting orientation. Astera tubes remain static models with instance placement.

Run a mixed 64-object scene and check the existing eight-beam budget, selection priority, loading time and memory. Do not infer headset performance from the Linux suite or simulator. Room scanning, World Sensing, physical gestures and live setup reopen require the headset.

Two packaged models remain explicitly `visual_review_pending`: ETC ColorSource PAR jr and Astera AX5 TriplePAR. Their lens counts, reflector cups and mount topology are corrected, but normalizing the sourced assembled envelope leaves the round optical housing vertically stretched in the front view. Resolve neutral-pose proportions from the drawings before clearing these two findings in `research/fixtures/expansion-v2/visual-review-issues.json`. Do not treat a native import pass as approval of their shape.

`models/rig.json` companions—not baked USDZ animation clips—drive the existing `FixtureRig`. Preview channels use synthetic VV Preview 16; manufacturer DMX, unlimited physical rotation, individual RGB pixel programming, gobos, smoke particles and safety/effect firing are not implemented by this asset expansion. Models and pivots are image-informed approximations. Native validation is explicitly pending for this release; the earlier Mac pilot result does not validate these 93 additions.

Use this temporary file as the return channel: append dated results, Xcode/visionOS versions, commands, pass/fail counts, screenshots/logs, fixes and unresolved device-only gaps. Preserve the historical results below. Update the per-item native validation only for assets actually tested, republish CSV status, and integrate/version/tag/push under `AGENTS.md`; do not touch `master`.

## Previous pickup — 127 existing assets

Pull `dev`, read `AGENTS.md`, and create an isolated task worktree. This rollout starts from the Mac's v0.1.22 scene inspector and spatial controls. It bundles 127 existing USDZ models and adds 128 preview joints across 72 assets, with the remaining 55 static. Search/filter, model dimensions, selection, extra joint controls, saved per-instance overrides, and head/mount targeting now use the generated catalog. Eight simultaneous beam previews prioritize the selected fixture; all placed geometry and joints remain active. The new direct controls affect individual moving parts; the Mac's spatial mount controls remain in place.

Run from `apps/visionos`:

```sh
swift test --package-path Core
./scripts/test-session.sh
python3 Tests/verify-assets.py
xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume -destination 'generic/platform=visionOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume -destination 'generic/platform=visionOS' -derivedDataPath DerivedData-device CODE_SIGNING_ALLOWED=NO build
./scripts/run-demo.sh --blue --catalog-smoke
./scripts/run-demo.sh --blue --history-smoke
```

The new `--catalog-smoke` debug path imports every bundled model, resolves every rig member, exercises neutral/minimum/maximum poses and checks RealityKit emitter transforms against Core targeting math. Capture the Simulator console: expect 127 `CATALOG_RIG_PASS` lines followed by `CATALOG_SMOKE_PASS assets=127`. Treat `CATALOG_SMOKE_FAIL` as a failure even if the app continues running. The smoke constructs rigs without displaying every model; interactive visual review is still required. Existing Xcode folder resources include all new bundle assets, and generated Core source is discovered by Swift Package Manager.

Visually inspect Rogue R1X plus another moving spot and moving wash; GLP JDC1 and both tilting bars; Volero Wave modules; Dynasty Scan mirror; Entour Cyclone fan; MotionCamera; mirror shaft/ball; and a manual PAR or Fresnel bracket. Confirm fixed bases/brackets stay fixed, optics follow the moving body, and no source meshes disappear. Test search/category filter, cold asset loading, selection while loading, room switching, restore of older Rogue setups, per-module sliders, shared-preset isolation, gesture Undo/Redo, reset, named setup save/reopen, and head versus mount targeting availability. Place static and atmosphere equipment and confirm there is no unintended light. With nine emitting models, confirm the selected model receives beam priority and the UI accurately explains the eight-beam limit. A multi-head fixture may consume all eight beams.

Linux results: Swift 6.0.3 Core suite and session/audit/interaction checks passed in the existing `swift:6.0` container. OpenUSD checked all 127 rig paths, member ownership, rest poses, rigid transforms and hashes; those reports are under `assets/fixtures/*/*/validation/rig.json`. Catalog CSVs contain rig state and locations. Source Blender/USDZ geometry is unchanged; rig sidecars define the runtime animation. Native compilation, RealityKit imports and gestures of this rollout are pending. Record native results and any fixes here, then integrate and push under the repository version/tag rules. Retain any device-only gaps explicitly.

The following sections are historical pilot context and validation reports.

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

**Source and host.** Work started from current `dev` / `origin/dev` `bda9e09` (`v0.1.21`) in `agent/fixture-interaction`, created with `git worktree add -b agent/fixture-interaction .worktree/fixture-interaction dev`. All edits and tests ran in that worktree. SSH fetch failed with `Permission denied (publickey)`; `git -c credential.helper='!gh auth git-credential' fetch https://github.com/reactivepixel/venueVolume.git dev:refs/remotes/origin/dev --tags` succeeded using the existing GitHub CLI login. Code, regressions and screenshots are committed as `69f6567`. The owner subsequently authorized integration into `dev`, tagging and pushing; see the release validation below. `master` was untouched.

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


### Release validation — v0.1.22

The integration was prepared in the assigned worktree from current `dev` `bda9e09` using `git switch --detach dev` and `git merge --no-ff --no-commit agent/fixture-interaction`. No conflicts occurred. The final merge includes patch bumps to both npm package/lockfile versions, `project.yml` and the regenerated Xcode project. Info.plist remains bound to `$(MARKETING_VERSION)`.

Re-ran `swift test --package-path Core` (39 tests), `./scripts/test-session.sh` (all four smoke groups), and `python3 Tests/verify-assets.py`: PASS. `./scripts/run-demo.sh --blue --transform-gizmo` built, installed and launched the release candidate; the unsigned generic visionOS device build passed too. Reading both built app Info.plist files with Python `plistlib` confirmed `CFBundleShortVersionString` is `0.1.22` for `Debug-xrsimulator` and `Debug-xros`. [Updated wrist version capture](../Screenshots/toolbox-version.png) displays v0.1.22 alongside the rings and inspector. Capture command: `xcrun simctl io 37FB51A4-DFF5-40C0-BFE1-32F8AA69EE4F screenshot Screenshots/toolbox-version.png`.

The release uses an annotated `v0.1.22` tag on the final merge commit, with `python3 apps/visionos/scripts/check-version.py --release` required before publishing `dev` and the tag. Direct Simulator gestures and physical headset acceptance remain open as described above.

## Mac and headset results — 2026-10-01, Toolbox window and selection repair

**Source.** `agent/toolbox-window-selection` in `.worktree/toolbox-window-selection`, based on `dev` v0.1.22 (`73c144c`). Implementation, regression coverage and screenshot: `62bd38b`. The primary checkout already had local Xcode project/signing edits; they were preserved. The signed command uses the owner's existing team as a build override. This is a development build with bundle version 0.1.22, not a new tagged release.

**Changes.** The Toolbox is now a normal `WindowGroup` with its system movement bar and a header X. Palm tracking issues an opening request only on the debounced rising edge. Lowering the hand leaves the window in place; closing it while the palm remains raised keeps it closed. Lowering and raising again recalls a fresh window instance near the current view. Manual recall remains available when hand tracking is unavailable and in Simulator. The window is no longer attached to or following the left hand. Window callbacks track instance identity so a departing window cannot mark its replacement closed.

The zero-distance drag recognizer now matches only `SpatialDragTarget` entities: axis handles and room surfaces while retargeting. It no longer competes with ordinary fixture taps. Removed the enclosing background collision sphere, disabled coarse placement proxies during normal selection, and enabled preset drop panels only during active preset drags. Fixture and gizmo inputs use indirect selection to avoid accidental direct-hand activation. Visible room-surface taps continue to deselect.

**Verification.** Xcode 27.0 (27A266a); Simulator visionOS 27.0 (24M362), UDID `37FB51A4-DFF5-40C0-BFE1-32F8AA69EE4F`. Chris’s physical Apple Vision Pro: visionOS 27.0 (24M362), Developer Mode enabled, UDID `00008112-001619923CC1A01E`.

Commands run from `apps/visionos` in the assigned worktree:

| Command | Result |
| --- | --- |
| `swift test --package-path Core` | PASS: 39 tests. |
| `./scripts/test-session.sh` | PASS: session, room, audit and interaction checks. New coverage tests single activation per held palm, staying open when lowered, close-with-palm-raised, reactivation and manual recall. |
| `python3 Tests/verify-assets.py` | PASS. |
| `./scripts/run-demo.sh --blue --input-smoke` | Simulator build/install/launch PASS. |
| `xcrun simctl launch --console-pty --terminate-running-process 37FB51A4-DFF5-40C0-BFE1-32F8AA69EE4F com.venuevolume.VenueVolume --demo -ApplePersistenceIgnoreState YES --blue --input-smoke` | `TOOLBOX_WINDOW_SMOKE_PASS` and `SPATIAL_INPUT_SMOKE_PASS`. Real window creation, close, reopen and recall callbacks were observed. A RealityKit ray reaches the fixture collider as the nearest enabled indirect input target; command routing selects it, room taps deselect it, ordinary fixture targets reject held manipulation, and aim surfaces gain/lose drag eligibility with retarget mode. |
| `xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume -destination 'id=00008112-001619923CC1A01E' -derivedDataPath DerivedData-device DEVELOPMENT_TEAM=3M53U7Y396 -allowProvisioningUpdates build` | Signed physical-device BUILD SUCCEEDED. |
| `codesign --verify --deep --strict 'DerivedData-device/Build/Products/Debug-xros/Venue Volume.app'` | PASS. |
| `xcrun devicectl device install app --device 00008112-001619923CC1A01E 'DerivedData-device/Build/Products/Debug-xros/Venue Volume.app' --json-output /tmp/vv-toolbox-install.json` | PASS: installed `com.venuevolume.VenueVolume` on the physical headset. |
| `xcrun devicectl device process launch --device 00008112-001619923CC1A01E --terminate-existing --json-output /tmp/vv-toolbox-launch.json com.venuevolume.VenueVolume --demo --blue` | PASS on retry: activated PID 1007. The initial launch was rejected with `SFBSurfBoardErrorDomain` code 50, “Application launch not allowed in current system mode (Enrollment Mode Update).” The system mode subsequently cleared. |
| `xcrun devicectl device info processes --device 00008112-001619923CC1A01E --json-output /tmp/vv-toolbox-processes.json` | Confirmed Venue Volume PID 1007 still running after launch. |
| `python3 scripts/check-version.py` | PASS for the current v0.1.22 baseline. |
| `git diff --check` | PASS. |

[Native Toolbox window capture](../Screenshots/toolbox-window.png), captured with `xcrun simctl io 37FB51A4-DFF5-40C0-BFE1-32F8AA69EE4F screenshot Screenshots/toolbox-window.png`, shows the header X, system movement bar, selected fixture pane and manual recall control. This is a Simulator capture, not a headset screenshot. The Simulator emits an appearance-transition warning during rapid scripted window recall, but window lifecycle and spatial input assertions pass. Native builds emit the routine unused AppIntents metadata warning.

**Acceptance boundary.** Signed hardware installation and foreground launch are now verified. Physical palm activation, positioning the window by hand, fixture gaze/pinch selection and sustained held targeting still require the wearer's confirmation; the user was asked to try those behaviors after launch. Live room scanning was not exercised in this repair. The demo launch uses its separate demo data and does not replace the normal saved arrangement.

## Mac validation results — 2026-10-01, preset targets and blackout

**Source.** Created `agent/preset-target-blackout` with `git worktree add -b agent/preset-target-blackout .worktree/preset-target-blackout dev`, then `git -C .worktree/preset-target-blackout merge --ff-only agent/toolbox-window-selection` to retain the previously deployed normal Toolbox window and selection repairs. All edits/builds/tests ran in this worktree. `dev` remains v0.1.22; neither integration nor a new release was requested for this change. The primary checkout's user-modified Xcode signing settings and `master` are untouched.

**Behavior.** Fixture **Retarget DMX** starts from its assigned saved preset. Editor **Target** starts from the current draft, using its non-aim channels during the preview. Save writes resolved Pan/Tilt to the preset, clears legacy aim overrides on affected assignments, updates assigned fixtures, and assigns the editor preset to the selected fixture. A named new draft can be targeted, saved and assigned. Changes are validated before publication and form one Undo step. Cancel preserves the draft and committed fixture state. Selection changes, preset navigation and clearing an assignment cancel pending targeting. Unrelated unsaved drafts survive a scene retarget. Mount aiming was removed from all menus; the axis controls still transform the mount.

Preset editing defaults to simulation. **Blackout simulation** mutes the selected simulated fixture without changing channel data. It is recorded in history with backward-compatible decoding of older snapshots. Global Toolbox Blackout still mutes every fixture. Both active blackout scopes show a black Toolbox background, sparse scrolling stars and an explicit scope label. The background ignores input and respects Reduce Motion. New drafts start unnamed; Save as new opens with an empty name, rejects whitespace-only names and clears the alert's field after success.

**Host.** Xcode 27.0 (27A266a). Simulator visionOS 27.0 (24M362), UDID `37FB51A4-DFF5-40C0-BFE1-32F8AA69EE4F`. Physical Chris’s Apple Vision Pro, UDID `00008112-001619923CC1A01E`, visionOS 27.0 (24M362), Developer Mode enabled, signing team `3M53U7Y396`.

**Commands/outcomes** (from this worktree's `apps/visionos`):

| Command | Outcome |
| --- | --- |
| `swift test --package-path Core` | PASS: 39 tests. Log `/tmp/vv-preset-core.log`. |
| `./scripts/test-session.sh` | PASS: session, room session, audit and interaction groups. Covers preset target Save/Cancel, latest non-aim draft values, shared assignments, independent new preset targeting, persistence, grouped Undo/Redo, simulation defaults, blackout scope/data preservation/history, blank-name rejection, navigation/clear cancellation, and older audit snapshot decoding. Log `/tmp/vv-preset-session.log`. |
| `python3 Tests/verify-assets.py` | PASS: room/fixture checksums and articulation/emitter metadata. |
| `xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume -destination 'id=00008112-001619923CC1A01E' -derivedDataPath DerivedData-device DEVELOPMENT_TEAM=3M53U7Y396 -allowProvisioningUpdates build` | BUILD SUCCEEDED, signed physical-device build. Log `/tmp/vv-preset-device-build.log`. |
| `codesign --verify --deep --strict 'DerivedData-device/Build/Products/Debug-xros/Venue Volume.app'` | PASS. |
| `xcodebuild -project VenueVolume.xcodeproj -scheme 'VenueVolume Demo' -destination 'id=37FB51A4-DFF5-40C0-BFE1-32F8AA69EE4F' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build` | BUILD SUCCEEDED. Log `/tmp/vv-preset-simulator-build.log`. |
| `./scripts/run-demo.sh --blue --show-preset-editor --blackout` | Built, installed and launched in Simulator; Toolbox blackout label/black background/stars visible, surrounding panels keep their normal appearance. |
| `xcrun simctl launch --console-pty --terminate-running-process 37FB51A4-DFF5-40C0-BFE1-32F8AA69EE4F com.venuevolume.VenueVolume --demo -ApplePersistenceIgnoreState YES --blue --history-smoke --input-smoke` | `SPATIAL_INPUT_SMOKE_PASS` and `TOOLBOX_WINDOW_SMOKE_PASS`. Initial room assertion failed because saved setup restore deliberately remaps a changed shared preset. See repair below. Log `/tmp/vv-preset-native-smoke.log`. |
| `xcrun simctl launch --console-pty --terminate-running-process 37FB51A4-DFF5-40C0-BFE1-32F8AA69EE4F com.venuevolume.VenueVolume --demo -ApplePersistenceIgnoreState YES --blue --history-smoke` | After correcting the obsolete assertion: `ROOM_LIBRARY_SMOKE_PASS`, `AUDIT_HISTORY_SMOKE_PASS`. Exercises synthetic mesh placement, preset target save, saved pose/look restore, axis Undo/Redo, cross-room history and deletion restoration. Log `/tmp/vv-preset-history-smoke.log`. |
| `xcrun devicectl --timeout 45 device install app --device 00008112-001619923CC1A01E 'DerivedData-device/Build/Products/Debug-xros/Venue Volume.app' --json-output /tmp/vv-preset-install.json` | PASS: final signed app installed, bundle `com.venuevolume.VenueVolume`, database sequence 1120. |
| `xcrun devicectl --timeout 45 device process launch --device 00008112-001619923CC1A01E --terminate-existing --json-output /tmp/vv-preset-launch.json com.venuevolume.VenueVolume` | TIMEOUT after 45 seconds. An earlier unbounded launch was interrupted after several minutes without a result. No demo/reset flags were supplied; normal saved data is retained. Install succeeded, but physical launch is not confirmed. |
| `python3 scripts/check-version.py` and `git diff --check` | PASS. Existing version remains 0.1.22 pending a separately authorized integration/release. |

**Test repair.** Retargeting now changes the shared preset, so reopening the original classroom setup correctly gives it an independent preset definition to preserve its saved look. The old smoke expected an identical preset UUID and failed. It now checks every fixture property (including fixture identity, pose and channels) while allowing only that assignment remap, and separately verifies the remapped library preset resolves to the original saved channels. The final replay and history checks pass. The axis gesture test also flushes the newly default-enabled simulation toggle before counting gesture events, keeping its one-Undo assertion scoped to the gesture.

**Evidence.** Native Simulator captures: [Blackout Toolbox](../Screenshots/preset-editor-blackout.png), [preset editor Target and simulation](../Screenshots/preset-editor-target.png), [room/history replay result](../Screenshots/preset-target-history.png). Captured with `xcrun simctl io 37FB51A4-DFF5-40C0-BFE1-32F8AA69EE4F screenshot Screenshots/<name>.png`. Editor presentation uses `--demo -ApplePersistenceIgnoreState YES --blue --show-preset-editor --palm-hidden`; these are seeded states, not simulated user gestures. No recording made.

**Remaining device validation.** The app is installed, but remote launch timed out. Asked the user to wear/unlock the headset and return to Home View; launch requires retry or manually opening Venue Volume there. CUA reported the Mac locked, blocking direct Simulator input testing. Physical gaze/pinch selection, held-hand Target adjustment, Save/Cancel activation, preset-name entry, palm recall, blackout animation comfort/Reduce Motion, live World Sensing scan and placement on a real scan are **not tested in this validation**. Simulator screenshots and command smoke checks do not establish those device behaviors.

### Integration validation — 2026-10-03, v0.1.27

Pulled `origin/dev` at `68a3b18` (v0.1.26) into `agent/integrate-preset-target`, created from local dev in `.worktree/integrate-preset-target`. Merged `agent/preset-target-blackout` (`6e61439`), including the earlier Toolbox window/selection fixes, with `git merge --no-ff --no-commit agent/preset-target-blackout`. Resolved conflicts in the model, renderer, fixture actions, interaction tests and README, retaining catalog search/loading, rigged joints, multi-emitter light budgeting and model-specific placement checks. DMX preset targeting now uses the catalog's head-aim eligibility rather than limiting it to the original Rogue R1X. Target saves clear conflicting legacy Pan/Tilt joint overrides; focused coverage verifies catalog target Save, Undo and Redo over those overrides while retaining bar/fan regressions.

Validation from `apps/visionos`: `swift test --package-path Core` passed 45 tests; `./scripts/test-session.sh` passed session, room, audit, interaction and catalog checks; `python3 Tests/verify-assets.py` passed the room/pilot checks and all 252 bundled catalog models/rig companions. `xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume -destination 'generic/platform=visionOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build` passed after repairing a catalog loader compile error: renderer asset completion must not mutate the model's protected DMX revision. A separate observed render counter now refreshes loaded placeholders without changing sync state. Build emitted only the routine AppIntents metadata warning. Logs: `/tmp/vv-integration-core.log`, `/tmp/vv-integration-session.log`, `/tmp/vv-integration-assets.log`, `/tmp/vv-integration-build.log`. `git diff --check` passed.

Both npm app package/lockfile versions, visionOS `MARKETING_VERSION` and generated Xcode project were bumped to 0.1.27 in the merge commit. Info.plist remains bound to `$(MARKETING_VERSION)`. Release requires annotated `v0.1.27` on this merge and `python3 apps/visionos/scripts/check-version.py --release` before pushing. No new headset deployment or physical gesture/scan validation was performed during this integration. The previous device launch timeout and wearer acceptance gaps remain open.
