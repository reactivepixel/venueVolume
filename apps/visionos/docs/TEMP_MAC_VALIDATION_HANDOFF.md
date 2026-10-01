# Temporary Mac handoff: moving-head pilot

Status: awaiting native validation. Keep this file until the Mac findings have been reviewed.

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
