# Venue Volume for visionOS

A runnable RealityKit lighting proof of concept for Simulator and Vision Pro (visionOS 2+). Place a catalog moving-head fixture in the reconstructed classroom, move its base, aim its head with DMX preview channels, and light the room with real dynamic spotlights and shadows.

## Run

Open `VenueVolume.xcodeproj` in Xcode. Choose **VenueVolume Demo** for an immediately populated room, or **VenueVolume** for your saved arrangement. On a development Vision Pro, select your signing team, pair/unlock the headset, choose it as the destination, and run. Allow hand tracking for the left-palm toolbox; manual access is available if permission is denied.

For an already booted visionOS Simulator, from this directory:

```sh
./scripts/run-demo.sh
```

The script builds, installs, and launches the demo. `VV_SIMULATOR_ID` selects a particular booted device. Extra arguments are forwarded, for example `./scripts/run-demo.sh --blue --palm-hidden`. Demo mode is available on both Simulator and hardware and never writes normal placements or presets.

## Use

1. Raise your **left palm** toward you to reveal **Toolbox**. Simulator supplies a **Left palm facing me** toggle. The trigger uses hand pose and head direction, not raw eye gaze.
2. Choose **Add fixture**, then select the top of a clear floor or table. A catalog Rogue R1X Spot visualization appears with its base on that surface. Initial output is zero. The proof of concept allows four moving-head fixtures.
3. Drag a preset from the library or Recent column onto the fixture or label. This commits the saved preset and lights the scene. Recent retains the last ten unique actions/objects/presets.
4. Select the fixture for **Info** and **Delete**. Info remains read-only. **Open fixture controls**, or **Fixture controls** in Toolbox, opens the companion window.
5. In **DMX preset**, edit channels and enable **Preview draft on selected fixture** to see edits immediately without changing saved values. Disable preview or close the window to restore the committed look. **Save preset** updates all assigned fixtures. **Save as new** makes an independent preset; **Apply saved** assigns it.
6. Switch to **Fixture position** for X/Y/Z in room meters and base yaw. These changes save immediately and do not alter its preset. **Move to floor** sets base height to zero. Use DMX pan/tilt to aim the head independently.
7. **White model** switches between neutral PBR materials and the room's original materials. **Room light** adjusts ambient illumination. **Blackout** temporarily disables fixture output, leaving room light and saved values intact.

The editor also supports previous/next, New, clear draft, revert, delete, clear assignment, and dirty-navigation confirmation. If a companion window is restored after relaunch without the room, its Enter venue button restores access; demo mode enters automatically. Channel editing stays in the preset window. The mock sync remains available in Toolbox and Diagnostics; it never sends lighting/network output.

## The room and asset

This task was based on GitHub `reactivepixel/venueVolume`, `origin/dev` **619f0d7** (v0.1.15), combined with the palm-toolbox branch **e29e107**.

The room is the existing **IMG_3153 classroom**, not a newly reconstructed scan. The current documented pipeline is movie references → reviewed room specification → Blender mesh → USDZ + environment manifest (`apps/room2blender`). `mov2splat` is a separate optional Gaussian experiment. This proof does not run movie reconstruction or automatically convert arbitrary splats into meshes.

The shipped classroom has 18,744 triangles, 68 mesh chunks, 96 collision boxes, and 11 floor/table placement surfaces. Its opaque mesh supplies depth occlusion and receives/casts dynamic-light shadows. No `OcclusionMaterial` is required for this fully virtual room: that would hide the surfaces we need to light. The file's estimated meter scale, Y-up coordinates, spawn pose, checksum, and per-room-version placement storage are preserved. The app enters **full immersion** to view the captured remote room; it does not register it to the wearer's physical room.

**White model** is a reversible runtime material override of that classroom geometry. The source USDZ is unchanged. Turn it off to see the original materials. The intended room assumption is the reconstructed classroom; there is no separately named white-room asset in the fetched repository.

The fixture comes from `assets/fixtures/chauvet-professional/rogue-r1x-spot`, revision 2. The bundled USDZ and metadata are byte-identical copies. It is an original procedural visualization proxy, not manufacturer CAD. The runtime reparents Head beneath Yoke while preserving its rest transform, then adds `SpotLightComponent` and `SpotLightComponent.Shadow` at the authored emitter. The fixture's own meshes do not cast shadows, avoiding lens self-occlusion; room meshes do. Imported opaque surfaces naturally hide fixtures behind them; room collider targets block placement taps through walls.

## Preview personality

**VV Preview 16** is a synthetic visualization profile, **not the Rogue R1X manufacturer's DMX map**. The catalog lists manufacturer modes but their channel definitions are not transcribed. RGB mixing and variable beam width here are visualization controls and must not be interpreted as that product's physical capabilities.

| Channel | Preview function | Range |
| --- | --- | --- |
| 1 | Dimmer | 0–35,000 nominal lumens |
| 2–4 | Red, green, blue | 0–255 each |
| 5 | Pan | roughly −135° to +134°, 128 centered |
| 6 | Tilt | roughly −60° to +60°, 128 centered |
| 7 | Beam outer half-angle | 10–60°; inner angle is 70% |
| 8–16 | Unmapped/reserved | Stored and synced, no visual effect |

Lumens, RGB, beam, and material response are not photometrically calibrated. This is direct lighting without baked indirect bounce or volumetric haze. No manufacturer gobos, physical strobe, safety/reset channels, Art-Net, sACN, or hardware control are implemented. Room placement is bounded by floor/ceiling/walls; manual XYZ edits can intersect furniture and are not a rigging/physics solver. A person can physically walk through virtual geometry; colliders do not constrain wearer movement.

Normal-mode fixtures, asset IDs, transforms, preset assignments, and resolved channels persist per room version. Presets are stored separately in UserDefaults. Legacy cube saves remain readable. Draft preview, blackout, room-light level, material mode, and Recents are session-only. User-saved older generic presets retain their channel bytes; on a moving-head proxy those bytes are interpreted using the displayed preview personality.

This is a standalone visualization spike. The production research's immutable profile revisions, semantic partial presets, publish/arm boundaries, and calibrated lighting remain separate future work.

## Validation

Verified **2026-10-01**, Xcode 27:

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

26 Core tests and model/session checks cover mapping/clamping, preview isolation/release, save/save-as, preset propagation, placement bounds, transforms, persistence/re-entry, legacy decoding, patch conflicts, manifest integrity, and mock synchronization. Asset checks compare bundled room/fixture hashes with the source artifacts. Both simulator and unsigned device targets compile. Real Simulator captures show warm/blue output, changed pan, speaker shadows, blackout, and UI states.

The Mac was locked during verification, so interactive pinch/drag/drop/slider automation was unavailable. No physical Vision Pro was connected: code signing, device installation, physical hand detection, tracking alignment, comfort, frame time, and thermal performance still require device acceptance. Compilation is not a device rendering/performance test.

Demo presentation flags: `--blue`, `--blackout`, `--aim-left`, `--fixture-near`, `--palm-hidden`, `--show-info`, `--show-recents`, `--show-preset-editor`, `--position-tab`. These seed reproducible app states, not simulated user gestures. At default pan the whiteboard is lit; the left-pan case shows the speaker's cast shadow.

Screenshots: [blue light](Screenshots/white-room-blue.png), [pan and cast shadow](Screenshots/white-room-aim.png), [blackout](Screenshots/white-room-blackout.png), [toolbox](Screenshots/white-room-toolbox.png), [DMX controls](Screenshots/white-room-controls.png), [position controls](Screenshots/white-room-position.png). Older screenshots document earlier milestones.

`project.yml` is the project source of truth. Regenerate with `xcodegen generate` after adding files. The Environments and FixtureAssets folders must remain folder resources. If XcodeGen emits `BuildableName="VenueVolume.app"`, set it to `Venue Volume.app` in the shared schemes.

References: [Apple dynamic lights and shadows](https://developer.apple.com/videos/play/wwdc2024/10103/), [SpotLightComponent](https://developer.apple.com/documentation/realitykit/spotlightcomponent), [environment lighting weight](https://developer.apple.com/documentation/realitykit/environmentlightingconfigurationcomponent), and [the repository's current movie workflow](../../docs/05%20Operations/mov2splat-review.md).
