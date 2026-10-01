# Venue Volume for visionOS

A runnable RealityKit lighting proof of concept for Simulator and Vision Pro (visionOS 2+). Start in the white classroom, import another room, or capture a local mesh on Vision Pro. The clearly labeled **Moving head pilot** uses the CHAUVET Professional Rogue R1X Spot library model; place and aim it in any supported room, preview its beam, and save setups for each environment.

## Run

Open `VenueVolume.xcodeproj` in Xcode. Choose **VenueVolume Demo** for an immediately populated room, or **VenueVolume** for your saved arrangement. On a development Vision Pro, select your signing team, pair/unlock the headset, choose it as the destination, and run. Allow hand tracking for the left-palm toolbox; manual access is available if permission is denied.

For an already booted visionOS Simulator, from this directory:

```sh
./scripts/run-demo.sh
```

The script builds, installs, and launches the demo. `VV_SIMULATOR_ID` selects a particular booted device. Extra arguments are forwarded, for example `./scripts/run-demo.sh --blue --palm-hidden`. Demo mode is available on both Simulator and hardware and never writes normal placements or presets.

## Use

1. Raise your **left palm** toward you to reveal **Toolbox**. Simulator supplies a **Left palm facing me** toggle. The trigger uses hand pose and head direction, not raw eye gaze.
2. In **Fixtures & presets**, drag **Rogue R1X moving head pilot** or **DMX cube** onto a highlighted floor/table surface. Alternatively select the fixture row, then pinch a clear surface. **Add moving head pilot** selects the Rogue R1X visualization. Initial output is zero. The proof of concept allows four moving-head lights and 64 total fixtures. The toolbox follows above the left wrist and holds its position during a drag.
3. Drag a preset from the library or Recent column onto the fixture or label. This commits the saved preset and lights the scene. Recent retains the last ten unique actions/objects/presets.
4. Select a fixture for **Info**, **Delete**, **Move**, **Retarget**, and **Transform**. Info remains read-only. **Move** arms a floor/table pick that repositions the existing object while preserving its orientation, patch, and DMX values. **Transform** opens the companion window’s position tab.
5. In **DMX preset**, edit channels and enable **Preview draft on selected fixture** to see edits immediately without changing saved values. Disable preview or close the window to restore the committed look. **Save preset** updates all assigned fixtures. **Save as new** makes an independent preset; **Apply saved** assigns it.
6. In **Fixture position**, adjust X/Y/Z in room meters and mount **yaw, pitch, and roll**. The **Moving head pilot** section also has direct **Pan** and **Tilt** sliders in degrees; these animate this fixture's head and beam, save a per-fixture aim override, and leave the shared preset unchanged. **Use preset aim** restores its preset angles. **Move to floor** sets base height to zero; **Upright mount** resets mounting orientation.
7. Choose **Retarget → Aim head (preview)**, look at a point on the room, then pinch (click the surface in Simulator). The head animates toward it and stores the corresponding preview pan/tilt bytes on that fixture. **Aim mount** rotates the entire asset to point the light at the target while keeping its preview values. A head-following prompt offers **Cancel**. Unreachable head targets leave the fixture unchanged and explain how to retry.
8. **White model** switches between neutral PBR materials and the room's original materials. **Room light** adjusts ambient illumination. **Blackout** temporarily disables fixture output, leaving room light and saved values intact.

The editor also supports previous/next, New, clear draft, revert, delete, clear assignment, and dirty-navigation confirmation. If a companion window is restored after relaunch without the room, its Enter venue button restores access; demo mode enters automatically. Channel editing stays in the preset window. The mock sync remains available in Toolbox and Diagnostics; it never sends lighting/network output.

## Rooms and saved setups

Open **Rooms & saved setups** in the wrist Toolbox. The left column lists environments; the right lists saved fixture setups across those environments. The bundled white classroom is the default on first launch. Subsequent normal sessions resume the active room and state from audit history.

- **Import** accepts a folder containing `environment.json` and its referenced `environment.usdz` or `environment.mesh.json`, or a standalone meter-scale USDZ. Bundles retain their reviewed placement surfaces, spawn pose, version, and checksum. Standalone USDZ imports infer a rectangular floor from the lowest visual bounds; provide a prepared room bundle for accurate floor/table placement metadata.
- **Scan** is available on Vision Pro. It opens a mixed-immersion capture view, requests World Sensing permission, and displays the observed mesh over passthrough. Look around to capture floor, walls, and furniture, including the floor beneath you. Name it and choose **Save room & open**. The scan becomes a selectable environment stored on this device. Cancel returns to the previous scene.
- Select an environment to open a blank setup. Place fixtures, apply presets, then name the setup and choose **Save**. **Save as new** preserves the previous setup as an independent instance. **New blank** clears the current arrangement while retaining the room geometry and all named saves. Switching away from changed fixtures offers Save, Discard, or Cancel.
- Select a saved setup to restore its room, fixtures, transforms, patch, resolved DMX values, per-fixture aim overrides, white/original material mode, and room-light level. Referenced preset definitions are included. If a shared preset has changed, restoration reuses an equivalent definition or creates an independent copy, preserving the saved look without modifying other setups.

Room geometry is immutable and shared by its setups. Named snapshots are separate from the existing per-room working-arrangement autosave. Normal library data lives beneath Application Support at `VenueVolume/Placements/Library`; demo saves use `DemoLibrary` and do not alter normal saved data. Saves are atomic, and invalid existing working files are preserved rather than overwritten. There is no cloud backup or room export UI yet.

Local capture uses ARKit scene reconstruction, not RoomPlan or movie reconstruction. It stores geometry, not photographic textures, with a limit of one million triangles / 2,048 mesh chunks. Unseen surfaces remain absent. Fixture placement on scan meshes checks horizontal support beneath the center and footprint corners; this is a sampled support check, not a collision or rigging solver. Captured rooms reopen as neutral, lightable meshes in full immersion, aligned to the saved spawn pose. They are not relocalized onto the original physical room. Simulator cannot scan, but can import and replay the same saved mesh format.

## Audit history, Undo and Redo

**Undo** and **Redo** stay visible at the top of the wrist Toolbox and in the fixture editor. A connected keyboard can use Command-Z and Shift-Command-Z. Open **History** in the toolbox for a timestamped event list; **Restore** returns to the state immediately after that event, including its room when necessary.

History covers fixture insertion/deletion/selection/info, position/orientation/aim, preset application/clearing/deletion/saving, preset drafts, room light/materials/blackout, room import or scan registration, room/setup loading, setup naming, and Save/Save as new. Multi-object preset updates and each continuous slider gesture form one undo step. Text/direct edits are grouped after 400 ms of inactivity and flushed before commands, navigation, leaving the venue, and app backgrounding. An abrupt process termination can lose an unfinished gesture or pending text edit. Tracking frames, hover, palette tabs, and transient drag/pick modes do not fill the log; restore cancels in-progress spatial gestures and clears Recent items.

The timeline retains branches: editing after Undo clears the immediate Redo route, but older events remain selectable in History. Undo, Redo, and Restore append navigation entries without deleting prior events. Snapshots include active room identity, fixture state, the preset library and draft, saved-setup catalog and active setup, selection, and lighting settings. Normal sessions resume the current cursor and retain undo/redo after relaunch.

Room geometry stays immutable. Undoing import/capture removes a room from the visible catalog while retaining its bytes for future replay. Undoing a named save restores the earlier catalog/version; retained snapshot files are not treated as new saves on restart. The audit cursor is authoritative once initialized. Asset loading and validation finish before a cross-room restore is committed; a failed restore leaves the current state and history position intact.

Mock sync requests/results, scan start/cancel/save failures, room-load failures, and leaving the venue are logged as external actions. History navigation never resends these actions or reverses a prior network request. Restoring state clears its sync acknowledgment; use Sync explicitly afterward. Live AR sessions, OS windows, head/palm poses, and tracking permissions are not time-traveled.

The local journal is `Library/audit-history.json`, with immutable snapshots in `Library/audit-history.states/`, beneath the placement directory. Each change writes its new snapshot once and atomically replaces the smaller event/cursor index. Earlier snapshots and asset files are retained; no automatic history pruning or cloud backup is implemented. Demo runs use DemoLibrary and start a fresh demo timeline. A corrupt journal is preserved and disables history with a visible error; write failures are reported rather than silently claiming an event was logged. This is an application recovery log, not a tamper-proof compliance ledger.

## Retargeting behavior

Targeting uses concave static collision shapes generated from the 68 imported room meshes. During aiming, these replace the coarse floor/table/wall proxy targets, so a pick resolves to the visible mesh. Repositioning continues to use the reviewed placement surfaces. A cyan marker shows the last accepted target. This is a one-time aim, not a target lock: moving or rotating the fixture afterward preserves its channels and therefore changes the beam destination.

Head solving converts the room point through the inverse mounting transform, using the asset's authored head pivot and −Z optical axis. It accounts for the emitter offset and quantizes to the preview profile's 8-bit pan/tilt limits; targets beyond those limits are rejected. Mount solving accounts for emitter parallax while retaining current head articulation. Mount changes ease over 0.6 seconds. Pan and tilt interpolate their scalar angles over 0.6 seconds, staying within motor limits rather than taking a quaternion shortcut behind the fixture. The stored/mock-synced DMX bytes are the final destination values; this does not stream a physical motor fade.

Retargeted pan/tilt are a persisted **per-fixture aim override**. Applying or saving a shared preset updates the other channels and preserves each object's aim. The object label and preset editor display the override. **Reset** / **Use preset aim** restores that preset's pan/tilt (neutral if unassigned). Clearing or deleting an assignment turns off output while retaining the override. Draft preview can temporarily show the draft's pan/tilt; ending preview restores the committed fixture values, and starting targeting ends draft preview. A preset with fewer than six channels cannot replace an active aim override until it is reset.

## The room and asset

This task was based on GitHub `reactivepixel/venueVolume`, `origin/dev` **619f0d7** (v0.1.15), combined with the palm-toolbox branch **e29e107**.

The room is the existing **IMG_3153 classroom**, not a newly reconstructed scan. The current documented pipeline is movie references → reviewed room specification → Blender mesh → USDZ + environment manifest (`apps/room2blender`). `mov2splat` is a separate optional Gaussian experiment. This proof does not run movie reconstruction or automatically convert arbitrary splats into meshes.

The shipped classroom has 18,744 triangles, 68 mesh chunks, 96 collision boxes, and 11 floor/table placement surfaces. Its opaque mesh supplies depth occlusion and receives/casts dynamic-light shadows. No `OcclusionMaterial` is required for this fully virtual room: that would hide the surfaces we need to light. The file's estimated meter scale, Y-up coordinates, spawn pose, checksum, and per-room-version placement storage are preserved. The app enters **full immersion** to view the captured remote room; it does not register it to the wearer's physical room.

**White model** is a reversible runtime material override of that classroom geometry. The source USDZ is unchanged. Turn it off to see the original materials. The intended room assumption is the reconstructed classroom; there is no separately named white-room asset in the fetched repository.

The fixture comes from `assets/fixtures/chauvet-professional/rogue-r1x-spot`, revision 2. The bundled USDZ and metadata are byte-identical copies. It is an original procedural visualization proxy, not manufacturer CAD. The runtime reparents Head beneath Yoke while preserving its rest transform, then adds `SpotLightComponent` and `SpotLightComponent.Shadow` at the authored emitter. The fixture's own meshes do not cast shadows, avoiding lens self-occlusion; room meshes do. Imported opaque surfaces naturally hide fixtures behind them; room collider targets block placement taps through walls. The toolbox, floating fixture label, Info panel, and position controls all mark this asset as the moving-head pilot and identify its preview profile.

## Preview personality

**VV Preview 16** is a synthetic visualization profile, **not the Rogue R1X manufacturer's DMX map**. The catalog lists manufacturer modes but their channel definitions are not transcribed. RGB mixing and variable beam width here are visualization controls and must not be interpreted as that product's physical capabilities.

The pilot limits head travel to roughly 270° pan and 120° tilt so its one-shot room targeting has a single, reviewable range. The [manufacturer's Rogue R1X Spot specifications](https://chauvetprofessional.com/product/rogue-r1x-spot/) list 540° pan and 250° tilt for the physical fixture. This pilot is an aiming and placement workflow check, not a full mechanical travel simulation.

| Channel | Preview function | Range |
| --- | --- | --- |
| 1 | Dimmer | 0–35,000 nominal lumens |
| 2–4 | Red, green, blue | 0–255 each |
| 5 | Pan | roughly −135° to +134°, 128 centered |
| 6 | Tilt | roughly −60° to +60°, 128 centered |
| 7 | Beam outer half-angle | 10–60°; inner angle is 70% |
| 8–16 | Unmapped/reserved | Stored and synced, no visual effect |

Lumens, RGB, beam, and material response are not photometrically calibrated. This is direct lighting without baked indirect bounce or volumetric haze. No manufacturer gobos, physical strobe, safety/reset channels, Art-Net, sACN, or hardware control are implemented. Room placement is bounded by floor/ceiling/walls; manual XYZ edits can intersect furniture and are not a rigging/physics solver. A person can physically walk through virtual geometry; colliders do not constrain wearer movement.

Normal-mode fixtures, asset IDs, transforms, per-fixture aim overrides, preset assignments, and resolved channels autosave per room version. Presets are stored separately in UserDefaults and included in named setup snapshots. Legacy cube saves remain readable. Named setups also retain room-light level and material mode; draft preview, blackout, and Recents remain session-only. User-saved older generic presets retain their channel bytes; on a moving-head proxy those bytes are interpreted using the displayed preview personality.

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

37 Core tests and model/session checks cover room/setup round trips, immutable room versions, snapshot validation, mesh support, fixture drop commands, blank setups, save/save-as, restore/relaunch, preset conflict isolation, corrupt working-file preservation, and the existing aiming, placement, preview, patch, and sync behavior. Audit checks exercise exact undo/redo, gesture grouping, branching, draft/preset and aim restoration, catalog/save reversal, cross-room load failure, relaunch, external sync logging, and corrupt journal preservation. Asset checks compare bundled room/fixture hashes with the source artifacts. Both simulator and unsigned device targets compile. Native Simulator integration exercises bundle import, synthetic mesh replay, named setups, cross-room Undo/Redo, and undoing fixture deletion through the real model and renderer.

The Mac was locked during verification, so interactive pinch/drag/drop/slider automation was unavailable. Native drag gestures, live mesh capture, wrist following, code signing, device installation, tracking alignment, comfort, frame time, and thermal performance still require acceptance on a physical Vision Pro. Compilation and synthetic mesh replay do not establish that live headset capture works correctly.

Demo presentation flags: `--blue`, `--blackout`, `--aim-left`, `--fixture-near`, `--palm-hidden`, `--show-info`, `--show-recents`, `--show-preset-editor`, `--position-tab`, `--targeting`, `--retarget-head`, `--retarget-mount`. The last two call the same targeting commands as the UI five seconds after room alignment; `--targeting` leaves the pick pending. Demo launches dismiss a restored preset window unless `--show-preset-editor` is requested. These seed reproducible app states, not simulated user gestures. At default pan the whiteboard is lit; the left-pan case shows the speaker's cast shadow.

Retarget captures: [animation recording](Screenshots/fixture-retarget.mp4), [head aim](Screenshots/fixture-retarget-head.png), [mount aim](Screenshots/fixture-retarget-mount.png), [targeting prompt](Screenshots/fixture-targeting.png), [full transform controls](Screenshots/fixture-transform.png).

Room-library captures: [initial room library](Screenshots/room-library.png), [imported rooms and saved setups](Screenshots/room-library-saved.png). Launch `./scripts/run-demo.sh --blue --rooms-tab` to open this toolbox tab. Add `--library-smoke` to run the debug-only native integration check; it writes clearly labelled demo setups and a synthetic mesh replay fixture into DemoLibrary. The synthetic mesh is test data, not a headset scan.

Audit capture: [history and persistent Undo/Redo controls](Screenshots/audit-history.png). Run `./scripts/run-demo.sh --blue --history-smoke` to exercise room-library operations plus history navigation and finish in the History tab. This invokes the same commands as the UI; it does not simulate pinch gestures or keyboard shortcuts.

Earlier screenshots: [blue light](Screenshots/white-room-blue.png), [pan and cast shadow](Screenshots/white-room-aim.png), [blackout](Screenshots/white-room-blackout.png), [toolbox](Screenshots/white-room-toolbox.png), [DMX controls](Screenshots/white-room-controls.png), [position controls](Screenshots/white-room-position.png). Older screenshots document earlier milestones.

`project.yml` is the project source of truth. Regenerate with `xcodegen generate` after adding files. The Environments and FixtureAssets folders must remain folder resources. If XcodeGen emits `BuildableName="VenueVolume.app"`, set it to `Venue Volume.app` in the shared schemes.

References: [Apple dynamic lights and shadows](https://developer.apple.com/videos/play/wwdc2024/10103/), [SpotLightComponent](https://developer.apple.com/documentation/realitykit/spotlightcomponent), [static mesh collisions](https://developer.apple.com/documentation/realitykit/shaperesource/generatestaticmesh(from:)), [input targeting](https://developer.apple.com/documentation/realitykit/inputtargetcomponent), [transform animation](https://developer.apple.com/documentation/realitykit/hastransform/move(to:relativeto:duration:timingfunction:)), [environment lighting weight](https://developer.apple.com/documentation/realitykit/environmentlightingconfigurationcomponent), and [the repository's current movie workflow](../../docs/05%20Operations/mov2splat-review.md).

Capture references: [Applying mesh to real-world surroundings](https://developer.apple.com/documentation/visionOS/applying-mesh-to-real-world-surroundings), [SceneReconstructionProvider](https://developer.apple.com/documentation/arkit/scenereconstructionprovider), and [MeshAnchor](https://developer.apple.com/documentation/arkit/meshanchor).
