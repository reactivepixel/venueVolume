# Cue programming and wrist controls — 2026-10-14

## Behavior

- Left palm and wrist attention both recall the fixture/selection Toolbox after the same 350 ms dwell. Palm Map is an explicit Room placement action. Toolbox keeps fixture placement and Undo/Redo; the expanded context bar adds Toolbox, Undo/Redo and previous/current/next cue controls.
- The current cue is numbered 01–255. The scrollable picker highlights it. Unchanged fixture attributes track from earlier cues. Palette/phaser recording defaults to the current cue, and Save to specific cue records without changing the current cue or output.
- Draft changes preview immediately on the actual selection. Changing selection/cue or closing the editor records valid pending edits on the original cue and selection. Reading a mixed selection does not project the first fixture's look onto the others.
- Cue-local changes preserve the reusable palette library and other recorded overrides. Explicit library updates still propagate through linked recalls and phaser step sources. Cues persist in audit history and portable named setups; Undo/Redo includes cue values and the active number. Touring cues are scoped to their show/configuration.
- The flat diagram samples actual selected fixture output. One monotonic clock drives the diagram and fixture phasers. Pause freezes both; resume continues without a time jump.
- Static/Dynamic are separate 60 pt native buttons. A left-hand event targeted at UI reserves input from free-space navigation and no longer disables the target control during its own click.
- Removed the item editor window, its pop-out entries and the fixture-label Info action.

## Diagnosis

`apps/visionos/scripts/test-session.sh --interaction-regression` initially reproduced three failures: palm attention opened the map, a UI pinch set the global editing blocker, and editing after Apply did not preview on fixtures. The regression now passes. The pause defect had no shared state seam: the diagram owned a separate private clock. Its replacement is tested through `PalettePlayback` and actual `VenueModel.renderedChannels` output.

## Validation

- `swift test --package-path apps/visionos/Core`: 124 tests passed (12 XCTest + 112 Swift Testing).
- `apps/visionos/scripts/test-session.sh`: all session checks passed, including existing placement, targeting, selection, touring, macros, history and persistence. New checks cover cue isolation/tracking, explicit save destination, selection-following preview, repeated mode changes, shared pause, cue limits, portable setups and touring recall.
- visionOS Simulator build passed. Runtime `--demo --cue-smoke --movement-screenshot` passed cue saves/recall, Undo/Redo, 10 repeated mode switches, real fixture pause and hand-attention model routing. [Runtime evidence](evidence/2026-10-14-cues/simulator.txt), [session evidence](evidence/2026-10-14-cues/session.txt), [native editor screenshot](evidence/2026-10-14-cues/editor.png).
- Signed physical-device build and installation succeeded. Device launch timed out while the Vision Pro reported `passcodeRequired: true`; real-headset runtime and physical hand/gaze checks remain pending unlock. Simulator model checks do not validate human gaze/pinch ergonomics.
