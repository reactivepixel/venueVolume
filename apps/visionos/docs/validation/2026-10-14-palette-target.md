# Palette fixture targeting — v0.2.15

The palette editor exposes **Target Fixture(s)** above the Static/Dynamic editor. Look at a room surface and pinch to preview; holding and moving adjusts the point. Each selected moving head solves Pan/Tilt from its own placement, scale, orientation and supported joint ranges. Unsupported fixtures explain why targeting is unavailable. An unreachable point rejects the entire selection before a save.

**Save target to cue** records the current palette and a separate position solution for each selected fixture. It holds Pan/Tilt at that location while other phaser attributes continue. Reusable library palettes, unselected fixtures, earlier cues and mount transforms remain unchanged. Cancel discards the target preview; Save is one Undo step. Further non-position edits retain individual aim solutions in the active draft. Explicit Pan/Tilt edits leave that target constraint.

The three legacy **Retarget DMX** buttons were removed from fixture labels, fixture actions and placement controls. The inventory toggle is now labeled **Quantity-only equipment**. There are no DMX-labeled buttons in the native views.

## Automated coverage

`bash apps/visionos/scripts/test-session.sh` passes the full session suite, including new palette targeting checks for single and multiple fixtures, separate Pan/Tilt solutions, preview isolation, cancel, invalid target recovery, current/earlier cue isolation, unselected fixtures, color phasers, subsequent edits, Undo/Redo, persistence and touring-show isolation.

Native rendering smoke command after building and installing in Simulator:

```sh
xcrun simctl launch --terminate-running-process --console-pty SIMULATOR_ID \
  com.venuevolume.VenueVolume --demo --show-preset-editor --palette-target-smoke
```

This waits for editor selection to settle, previews a shared target with two rendered rigs, checks their individual solutions and saves to the cue. Programmatic targeting does not establish wearer gaze/pinch acceptance.

The native Simulator run passes:

```
PALETTE_TARGET_SMOKE_PASS multiFixture=true livePreview=true cueSave=true libraryUnchanged=true
```

The [native editor screenshot](palette-target/editor.png) was visually checked: Target Fixture(s) is visible above Static/Dynamic, with selection count and cue controls still available.

The final interaction regression subset also passes after adding missing-channel guards. The physical headset reports `passcodeRequired: true`; live headset checks remain pending unlock.

The signed device build passes and its built bundle version is 0.2.15. Installation on Chris's Apple Vision Pro succeeds on retry after an initial connection timeout. This confirms installation, not physical runtime acceptance.
