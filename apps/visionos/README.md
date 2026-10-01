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
4. Select a fixture for **Info**, **Delete**, **Move**, **Retarget**, and **Transform**. Info remains read-only. **Move** arms a floor/table pick that repositions the existing object while preserving its orientation, patch, and DMX values. **Transform** opens the companion window’s position tab.
5. In **DMX preset**, edit channels and enable **Preview draft on selected fixture** to see edits immediately without changing saved values. Disable preview or close the window to restore the committed look. **Save preset** updates all assigned fixtures. **Save as new** makes an independent preset; **Apply saved** assigns it.
6. In **Fixture position**, adjust X/Y/Z in room meters and mount **yaw, pitch, and roll**. These changes save immediately and do not alter the preset. **Move to floor** sets base height to zero; **Upright mount** resets mounting orientation.
7. Choose **Retarget → Aim head (DMX)**, look at a point on the room, then pinch (click the surface in Simulator). The head animates toward it and stores the corresponding pan/tilt bytes on that fixture. **Aim mount** rotates the entire asset to point the light at the target while keeping its DMX values. A head-following prompt offers **Cancel**. Unreachable head targets leave the fixture unchanged and explain how to retry.
8. **White model** switches between neutral PBR materials and the room's original materials. **Room light** adjusts ambient illumination. **Blackout** temporarily disables fixture output, leaving room light and saved values intact.

The editor also supports previous/next, New, clear draft, revert, delete, clear assignment, and dirty-navigation confirmation. If a companion window is restored after relaunch without the room, its Enter venue button restores access; demo mode enters automatically. Channel editing stays in the preset window. The mock sync remains available in Toolbox and Diagnostics; it never sends lighting/network output.

## Retargeting behavior

Targeting uses concave static collision shapes generated from the 68 imported room meshes. During aiming, these replace the coarse floor/table/wall proxy targets, so a pick resolves to the visible mesh. Repositioning continues to use the reviewed placement surfaces. A cyan marker shows the last accepted target. This is a one-time aim, not a target lock: moving or rotating the fixture afterward preserves its channels and therefore changes the beam destination.

Head solving converts the room point through the inverse mounting transform, using the asset's authored head pivot and −Z optical axis. It accounts for the emitter offset and quantizes to the preview profile's 8-bit pan/tilt limits; targets beyond those limits are rejected. Mount solving accounts for emitter parallax while retaining current head articulation. Mount changes ease over 0.6 seconds. Pan and tilt interpolate their scalar angles over 0.6 seconds, staying within motor limits rather than taking a quaternion shortcut behind the fixture. The stored/mock-synced DMX bytes are the final destination values; this does not stream a physical motor fade.

Retargeted pan/tilt are a persisted **per-fixture aim override**. Applying or saving a shared preset updates the other channels and preserves each object's aim. The object label and preset editor display the override. **Reset** / **Use preset aim** restores that preset's pan/tilt (neutral if unassigned). Clearing or deleting an assignment turns off output while retaining the override. Draft preview can temporarily show the draft's pan/tilt; ending preview restores the committed fixture values, and starting targeting ends draft preview. A preset with fewer than six channels cannot replace an active aim override until it is reset.

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

Normal-mode fixtures, asset IDs, transforms, per-fixture aim overrides, preset assignments, and resolved channels persist per room version. Presets are stored separately in UserDefaults. Legacy cube saves remain readable. Draft preview, blackout, room-light level, material mode, and Recents are session-only. User-saved older generic presets retain their channel bytes; on a moving-head proxy those bytes are interpreted using the displayed preview personality.

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

31 Core tests and model/session checks cover head/mount solving, emitter parallax, motor-limit rejection, Euler singularities, aim persistence/preset isolation, reposition/cancel/delete, mapping/clamping, preview isolation/release, save/save-as, preset propagation, placement bounds, transforms, persistence/re-entry, legacy decoding, patch conflicts, manifest integrity, and mock synchronization. Asset checks compare bundled room/fixture hashes with the source artifacts. Both simulator and unsigned device targets compile. Real Simulator captures show warm/blue output, retargeted head and mount, the target marker/prompt, transform controls, speaker shadows, blackout, and UI states.

The Mac was locked during verification, so interactive pinch/drag/drop/slider automation was unavailable. No physical Vision Pro was connected: code signing, device installation, physical hand detection, tracking alignment, comfort, frame time, and thermal performance still require device acceptance. Compilation is not a device rendering/performance test.

Demo presentation flags: `--blue`, `--blackout`, `--aim-left`, `--fixture-near`, `--palm-hidden`, `--show-info`, `--show-recents`, `--show-preset-editor`, `--position-tab`, `--targeting`, `--retarget-head`, `--retarget-mount`. The last two call the same targeting commands as the UI five seconds after room alignment; `--targeting` leaves the pick pending. Demo launches dismiss a restored preset window unless `--show-preset-editor` is requested. These seed reproducible app states, not simulated user gestures. At default pan the whiteboard is lit; the left-pan case shows the speaker's cast shadow.

Retarget captures: [animation recording](Screenshots/fixture-retarget.mp4), [head aim](Screenshots/fixture-retarget-head.png), [mount aim](Screenshots/fixture-retarget-mount.png), [targeting prompt](Screenshots/fixture-targeting.png), [full transform controls](Screenshots/fixture-transform.png).

Earlier screenshots: [blue light](Screenshots/white-room-blue.png), [pan and cast shadow](Screenshots/white-room-aim.png), [blackout](Screenshots/white-room-blackout.png), [toolbox](Screenshots/white-room-toolbox.png), [DMX controls](Screenshots/white-room-controls.png), [position controls](Screenshots/white-room-position.png). Older screenshots document earlier milestones.

`project.yml` is the project source of truth. Regenerate with `xcodegen generate` after adding files. The Environments and FixtureAssets folders must remain folder resources. If XcodeGen emits `BuildableName="VenueVolume.app"`, set it to `Venue Volume.app` in the shared schemes.

References: [Apple dynamic lights and shadows](https://developer.apple.com/videos/play/wwdc2024/10103/), [SpotLightComponent](https://developer.apple.com/documentation/realitykit/spotlightcomponent), [static mesh collisions](https://developer.apple.com/documentation/realitykit/shaperesource/generatestaticmesh(from:)), [input targeting](https://developer.apple.com/documentation/realitykit/inputtargetcomponent), [transform animation](https://developer.apple.com/documentation/realitykit/hastransform/move(to:relativeto:duration:timingfunction:)), [environment lighting weight](https://developer.apple.com/documentation/realitykit/environmentlightingconfigurationcomponent), and [the repository's current movie workflow](../../docs/05%20Operations/mov2splat-review.md).
