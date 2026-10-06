# Interaction, fixture groups, palettes and phasers

This change replaces continuous viewer manipulation with a palm map, adds repeated fixture placement and persistent fixture groups, and introduces palette/phaser authoring while retaining legacy serialized preset fields for saved-file compatibility.

## Validation environment

Implementation and portable tests run on Linux with the existing `swift:6.0` Docker image. This host has no Xcode, visionOS SDK, Simulator, or connected Vision Pro. Swift syntax parsing and portable model tests do not establish that RealityKit/SwiftUI code type-checks or that headset gestures work.

The pre-change baseline on `dev` (`c39e5e2`) passes 72 Core tests and all session smoke groups.

## Release verification

Final integrated results are recorded below after review.

## Native acceptance checks

On a Mac, regenerate the project using `xcodegen generate`, review the project diff, and build the application for both the visionOS Simulator and generic visionOS device. Run `swift test --package-path Core`, `bash scripts/test-session.sh`, and `python3 Tests/verify-assets.py`.

On a Vision Pro:

- Look toward/away from the bottom context bar and verify its dimming and recovery. Verify Done remains usable during repeated placement.
- Reveal the wrist toolbox repeatedly, close it while holding the pose, then lower/reveal again. Verify tracking interruptions do not permanently disable recall.
- Reveal the palm map and drag the viewpoint marker with the right-hand indirect pinch. Release commits one teleport without continuous camera motion. Tap without dragging exposes rotation controls. Verify each committed change is hidden by blackout and fades back using the configured duration, initially 333 ms.
- Verify the map marker corresponds to the viewer after walking, teleporting, and rotating, including near room edges. Tracking loss, leaving the space, or changing rooms must cancel an unfinished gesture.
- Place several fixtures without restarting placement; check the ghost against the committed surface position. Done ends placement. Verify overlapping/invalid patches are rejected without partial edits.
- Switch Move and Rotate, verify only the correct handles respond, and verify active axis emphasis. Check the padded base selection circles and animated group links.
- Multi-select and group fixtures, select a member to recover the entire group, edit the group, undo/redo, save/export/import/relaunch, and ungroup from the wrist toolbox. Confirm independently aimed fixtures point at the same target and DMX patch edits do not overlap.
- Keep the palette preview visible while scrolling the editor. Select and drag the cube's X/Y/Z handles; verify room-grid scale and the initial one-metre floor offset. Edit/duplicate a static palette and a phaser, save, and verify assigned scene fixtures animate with matching phase/timing.

Raw eye-gaze coordinates are not available to this application. Review any head-attention approximation separately from system-managed hover/indirect targeting; do not report either as direct eye tracking.
