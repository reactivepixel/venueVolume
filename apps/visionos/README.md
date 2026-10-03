# Venue Volume for visionOS

A runnable RealityKit lighting proof of concept for Simulator and Vision Pro (visionOS 2+). Start in the white classroom, import another room, or capture a local mesh on Vision Pro. The fixture library contains all 127 existing models, with 128 preview joints across 72 articulated assets. Search by model or manufacturer, filter by category, place models, preview supported motion and light, and save setups for each environment.

## Run

Open `VenueVolume.xcodeproj` in Xcode. Choose **VenueVolume Demo** for an immediately populated room, or **VenueVolume** for your saved arrangement. On a development Vision Pro, select your signing team, pair/unlock the headset, choose it as the destination, and run. Allow hand tracking for palm activation of the Toolbox window; manual access is available if permission is denied.

For an already booted visionOS Simulator, from this directory:

```sh
./scripts/run-demo.sh
```

The script builds, installs, and launches the demo. `VV_SIMULATOR_ID` selects a particular booted device. Extra arguments are forwarded, for example `./scripts/run-demo.sh --blue --palm-hidden`. Demo mode is available on both Simulator and hardware and never writes normal placements or presets.

The palm-activated Toolbox header shows the app's `CFBundleShortVersionString`, sourced from Xcode `MARKETING_VERSION` ([Simulator capture](Screenshots/toolbox-version.png)). Run `python3 scripts/check-version.py` from this directory to confirm it matches the latest reachable `vMAJOR.MINOR.PATCH` Git tag and both npm app versions. Release integration runs the check with `--release` after tagging to require an annotated tag at `HEAD`.

## Use

1. Raise your **left palm** toward you to open **Toolbox** as a normal visionOS window. Lower your hand: the window stays where it opened. Move it with the system window bar, or close it with the header **X** or system close control. Lower and raise your palm again to reopen or recall it near your current view. A held palm requests the window only once, so closing it does not immediately reopen it. Simulator supplies a **Left palm facing me** toggle and **Open / recall toolbox** button; the button also appears if hand tracking is unavailable. The trigger uses hand pose and head direction, not raw eye gaze.
2. In **Fixtures & presets**, search the catalog or choose a category, then drag a model onto a highlighted floor/table surface. Alternatively select its row and pinch a clear surface. **Add selected model** repeats that model. Initial light output and continuous motion are zero, with angular joints centered. Setups support 64 objects. Eight simultaneous beam previews are allocated to lit fixtures, with the selected fixture first; all placed models remain visible and articulated. The Toolbox remains a stationary window during drags.
3. Drag a preset from the library onto the fixture or label. This commits the saved preset and lights the scene. The right toolbox column shows a scene breakdown with each fixture's patch and preset, individual delete buttons, and **Clear all**. Clearing is undoable; room geometry and named setups remain available. Empty scenes show a placement guide.
4. Select a fixture for **Info**, **Delete**, **Move**, **Retarget**, and **Transform**. The right toolbox column becomes its info pane. **Pop out item editor** opens the full selected-item window, including name/patch editing and a Transform tab. Both panes follow the current selection. Click an unoccupied room surface/background, or the pane's deselect button, to clear selection, close the item window and return to the scene breakdown. **Move** arms a floor/table pick while preserving orientation, patch, and DMX values.
5. In **DMX preset**, **Simulate on selected fixture** starts enabled. Channel edits appear immediately without changing saved values. **Blackout simulation** temporarily mutes only that selected fixture, preserving draft and saved channels. Disable simulation or close the window to restore the committed look. **Save preset** updates all assigned fixtures. **Save as new** starts with an empty name field and clears it after a successful save; **New preset** also starts unnamed. **Apply saved** assigns the saved preset.
6. **Transform** / **Axes** displays colored 3D controls on the selected object: red X, green Y and blue Z. In **Rotate**, hold and drag a circular ring to rotate the mount around that room axis. In **Move**, drag an arrow along its axis. Each gesture forms one Undo step; these controls preserve DMX values. Position and mount angles are readouts in the pop-out editor, with **Upright mount** and **Reposition on surface** actions. **Use preset aim** restores the preset's head angles. DMX sliders remain in the preset editor.
7. Choose **Retarget DMX** on a fixture to target its currently assigned preset. In the preset editor, **Target** uses the current draft on the selected moving head, including unsaved channel edits. Look at a room point and pinch/click to preview; hold and move your hand to adjust continuously. **Save preset target** saves Pan/Tilt into that preset, updates its assigned fixtures, and assigns it to the selected fixture when started from the editor. A named new draft can be targeted and saved this way. Save is one Undo step; **Cancel** restores the previous look and leaves the editor draft intact. Changing fixture selection or navigating to another preset discards the pending target. The separate mount-aim mode is removed; mount rotation remains available through the axis controls.
8. **White model** switches between neutral PBR materials and the room's original materials. **Room light** adjusts ambient illumination. **Blackout** temporarily disables all fixture output, leaving room light and saved values intact. While global blackout or selected-fixture simulation blackout is active, Toolbox has a black background, a slowly scrolling starfield and an explicit scope label. The stars stop for Reduce Motion and disappear when blackout ends; no other pane changes its background.

The editor also supports previous/next, New, clear draft, revert, delete, clear assignment, and dirty-navigation confirmation. If a preset or item window is restored after relaunch without the room, its Enter venue button restores access; demo mode enters automatically. Channel editing stays in the preset window. The mock sync remains available in Toolbox and Diagnostics; it never sends lighting/network output.

## Rooms and saved setups

Open **Rooms & saved setups** in the Toolbox window. The left column lists environments; the right lists saved fixture setups across those environments. The bundled white classroom is the default on first launch. Subsequent normal sessions resume the active room and state from audit history.

- **Import** accepts a folder containing `environment.json` and its referenced `environment.usdz` or `environment.mesh.json`, or a standalone meter-scale USDZ. Bundles retain their reviewed placement surfaces, spawn pose, version, and checksum. Standalone USDZ imports infer a rectangular floor from the lowest visual bounds; provide a prepared room bundle for accurate floor/table placement metadata.
- **Scan** is available on Vision Pro. It opens a mixed-immersion capture view, requests World Sensing permission, and displays the observed mesh over passthrough. Look around to capture floor, walls, and furniture, including the floor beneath you. Name it and choose **Save room & open**. The scan becomes a selectable environment stored on this device. Cancel returns to the previous scene.
- Select an environment to open a blank setup. Place fixtures, apply presets, then name the setup and choose **Save**. **Save as new** preserves the previous setup as an independent instance. **New blank** clears the current arrangement while retaining the room geometry and all named saves. Switching away from changed fixtures offers Save, Discard, or Cancel.
- Select a saved setup to restore its room, fixtures, transforms, patch, resolved DMX values, per-fixture aim overrides, white/original material mode, and room-light level. Referenced preset definitions are included. If a shared preset has changed, restoration reuses an equivalent definition or creates an independent copy, preserving the saved look without modifying other setups.

Room geometry is immutable and shared by its setups. Named snapshots are separate from the existing per-room working-arrangement autosave. Normal library data lives beneath Application Support at `VenueVolume/Placements/Library`; demo saves use `DemoLibrary` and do not alter normal saved data. Saves are atomic, and invalid existing working files are preserved rather than overwritten. There is no cloud backup or room export UI yet.

Local capture uses ARKit scene reconstruction, not RoomPlan or movie reconstruction. It stores geometry, not photographic textures, with a limit of one million triangles / 2,048 mesh chunks. Unseen surfaces remain absent. Fixture placement on scan meshes checks horizontal support beneath the center and footprint corners; this is a sampled support check, not a collision or rigging solver. Captured rooms reopen as neutral, lightable meshes in full immersion, aligned to the saved spawn pose. They are not relocalized onto the original physical room. Simulator cannot scan, but can import and replay the same saved mesh format.

## Audit history, Undo and Redo

**Undo** and **Redo** stay visible at the top of the Toolbox window and in the fixture editor. A connected keyboard can use Command-Z and Shift-Command-Z. Open **History** in the toolbox for a timestamped event list; **Restore** returns to the state immediately after that event, including its room when necessary.

History covers fixture insertion/deletion/selection/info, position/orientation/aim, preset application/clearing/deletion/saving, preset drafts, room light/materials/blackout, room import or scan registration, room/setup loading, setup naming, and Save/Save as new. Multi-object preset updates, each axis drag and each continuous preset slider gesture form one undo step. Target adjustments remain transient until Save, which creates one step; Cancel does not change the journal. Text/direct edits are grouped after 400 ms of inactivity and flushed before commands, navigation, leaving the venue, and app backgrounding. An abrupt process termination can lose an unfinished gesture or pending text edit. Tracking frames, hover, palette tabs, and transient drag/pick modes do not fill the log; restore cancels in-progress spatial gestures and hides axis controls.

The timeline retains branches: editing after Undo clears the immediate Redo route, but older events remain selectable in History. Undo, Redo, and Restore append navigation entries without deleting prior events. Snapshots include active room identity, fixture state, the preset library and draft, saved-setup catalog and active setup, selection, and lighting settings. Normal sessions resume the current cursor and retain undo/redo after relaunch.

Room geometry stays immutable. Undoing import/capture removes a room from the visible catalog while retaining its bytes for future replay. Undoing a named save restores the earlier catalog/version; retained snapshot files are not treated as new saves on restart. The audit cursor is authoritative once initialized. Asset loading and validation finish before a cross-room restore is committed; a failed restore leaves the current state and history position intact.

Mock sync requests/results, scan start/cancel/save failures, room-load failures, and leaving the venue are logged as external actions. History navigation never resends these actions or reverses a prior network request. Restoring state clears its sync acknowledgment; use Sync explicitly afterward. Live AR sessions, OS windows, head/palm poses, and tracking permissions are not time-traveled.

The local journal is `Library/audit-history.json`, with immutable snapshots in `Library/audit-history.states/`, beneath the placement directory. Each change writes its new snapshot once and atomically replaces the smaller event/cursor index. Earlier snapshots and asset files are retained; no automatic history pruning or cloud backup is implemented. Demo runs use DemoLibrary and start a fresh demo timeline. A corrupt journal is preserved and disables history with a visible error; write failures are reported rather than silently claiming an event was logged. This is an application recovery log, not a tamper-proof compliance ledger.

## Retargeting behavior

Normal selection uses fixture colliders and visible room meshes; empty room-surface taps deselect. Preset drop overlays enable only during an active preset drag. Held gestures target only axis handles or room meshes during aiming, so ordinary fixture selection does not compete with a zero-distance drag recognizer. There is no enclosing input sphere.

Targeting uses concave static collision shapes generated from the 68 imported room meshes. During aiming, these replace the coarse floor/table/wall proxy targets, so a pick resolves to the visible mesh. Repositioning continues to use the reviewed placement surfaces. A cyan marker follows the unsaved target and remains at the saved target. This is a one-time aim, not a target lock: moving or rotating the fixture afterward preserves its channels and therefore changes the beam destination.

Head solving converts the room point through the inverse mounting transform, using the asset's authored head pivot and −Z optical axis. It accounts for the emitter offset and quantizes to the preview profile's 8-bit pan/tilt limits; targets beyond those limits are rejected. Mount changes ease over 0.6 seconds. Pan and tilt interpolate their scalar angles over 0.6 seconds, staying within motor limits rather than taking a quaternion shortcut behind the fixture. The stored/mock-synced DMX bytes are the final destination values; this does not stream a physical motor fade.

Retargeted Pan/Tilt are saved into the **current preset**, with no new per-fixture override. All fixtures assigned to that preset receive the saved DMX values, even though their differing positions may make their beams land elsewhere. To keep another fixture independent, use a different preset. Editor Target previews the draft on the selected fixture, then saves and assigns it; scene Retarget uses the assigned saved preset and preserves any unrelated unsaved editor draft. The complete assignment is validated before publication, including patch overlap, and Undo/Redo restores preset and fixture state together.

Older saved fixtures with aim overrides remain readable. Existing preset application/save compatibility still preserves those legacy overrides until **Use preset aim** or a new preset target save clears them. New targeting never creates an override. Targets outside the preview profile's Pan/Tilt limits are rejected. A preset needs a name and at least six channels for targeting.

## The room and asset

This task was based on GitHub `reactivepixel/venueVolume`, `origin/dev` **619f0d7** (v0.1.15), combined with the palm-toolbox branch **e29e107**.

The room is the existing **IMG_3153 classroom**, not a newly reconstructed scan. The current documented pipeline is movie references → reviewed room specification → Blender mesh → USDZ + environment manifest (`apps/room2blender`). `mov2splat` is a separate optional Gaussian experiment. This proof does not run movie reconstruction or automatically convert arbitrary splats into meshes.

The shipped classroom has 18,744 triangles, 68 mesh chunks, 96 collision boxes, and 11 floor/table placement surfaces. Its opaque mesh supplies depth occlusion and receives/casts dynamic-light shadows. No `OcclusionMaterial` is required for this fully virtual room: that would hide the surfaces we need to light. The file's estimated meter scale, Y-up coordinates, spawn pose, checksum, and per-room-version placement storage are preserved. The app enters **full immersion** to view the captured remote room; it does not register it to the wearer's physical room.

**White model** is a reversible runtime material override of that classroom geometry. The source USDZ is unchanged. Turn it off to see the original materials. The intended room assumption is the reconstructed classroom; there is no separately named white-room asset in the fetched repository.

Each bundled USDZ is an exact copy of its existing library model. `assets/fixtures/runtime-catalog.json` and each model's `models/rig.json` describe its parts, pivots, control channels, bounds, emitter anchors and bundle location. `FixtureRig` inserts transform nodes at those pivots and reparents the specified geometry while preserving the rest pose. It handles pan/tilt, linear fixture tilt, independent Volero Wave modules, scanner mirror motion, manual brackets, the tracking camera, fan rotor and mirror-ball components. Motion is interpolated in degrees over 0.6 seconds; continuous controls integrate rotational speed. These are original procedural approximations with estimated joints and synthetic travel. Existing Blender/USDZ geometry remains unchanged.

The item editor's **Transform → Moving parts** controls are specific to the selected model. A gesture makes one Undo step and stores a per-instance override. **Use preset motion** restores its preset values or neutral pose. Preset application preserves those overrides. Static equipment has placement and mount transforms. Atmosphere and effects equipment use their existing models and outlet metadata; particle effects and operational firing are not simulated.

Assets load on demand and their bytes are checked against the catalog hash. Selection targets use each model's bounds. Spot lights follow the rig's emitter transforms and share the eight-beam budget; each multi-head model divides its illustrative intensity across its emitters. Light fixture meshes do not cast shadows, avoiding lens self-occlusion; room meshes do. The original Rogue R1X pilot remains available and old saved setups retain their stable asset IDs.

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
| 8–15 | Model-specific additional motion | Volero Wave heads 1–8 tilt; channel 8 is speed for fan/mirror components |
| 16 | Reserved | Stored and synced |

The table describes the general moving-head preview. Model-specific channel labels appear in the editor: scanners use a smaller synthetic mirror range; manual tilt uses channel 6; stationary models omit pan/tilt; passive equipment has no light output. Manufacturer motor travel and calibrated mirror reflection remain outside this preview. Preset DMX targeting is enabled for moving light heads that support Pan/Tilt. Use joint controls and mount axis rotation for other models.

Lumens, RGB, beam, and material response are not photometrically calibrated. This is direct lighting without baked indirect bounce or volumetric haze. No manufacturer gobos, physical strobe, safety/reset channels, Art-Net, sACN, or hardware control are implemented. Room placement is bounded by floor/ceiling/walls; axis movement can intersect furniture and are not a rigging/physics solver. A person can physically walk through virtual geometry; colliders do not constrain wearer movement.

Normal-mode fixtures, asset IDs, transforms, per-fixture aim overrides, preset assignments, and resolved channels autosave per room version. Presets are stored separately in UserDefaults and included in named setup snapshots. Legacy cube saves remain readable. Named setups also retain room-light level and material mode; draft preview, blackout, pending targets and axis visibility remain session-only. User-saved older generic presets retain their channel bytes; on a moving-head proxy those bytes are interpreted using the displayed preview personality.

This is a standalone visualization spike. The production research's immutable profile revisions, semantic partial presets, publish/arm boundaries, and calibrated lighting remain separate future work.

## Validation

Use the [current Mac and headset checklist](docs/VALIDATION.md) for acceptance and the [dated validation archive](docs/validation/2026-10-01-to-03-mac-validation.md) for completed results. Run these reusable checks from `apps/visionos` in the assigned worktree:

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
./scripts/run-demo.sh --blue --catalog-smoke
./scripts/run-demo.sh --blue --history-smoke
./scripts/run-demo.sh --blue --input-smoke
```

The final recorded integration check on **2026-10-03**, Xcode 27, passed 45 Core tests, five session groups, bundle verification for 252 catalog models and a Simulator build. The model checks cover catalog articulation, room/setup persistence, preset targeting, Undo/Redo and input routing. Earlier native checks exercised pilot import, synthetic mesh replay, history and Toolbox window callbacks. Full-catalog runtime import and interactive visual review remain open; neither bundle verification nor compilation establishes them.

The earlier Toolbox repair was signed, installed and launched on a physical Vision Pro. The later preset-target build installed successfully, but its remote launch timed out. Wearer acceptance remains open: actual gaze/pinch and drag gestures, palm recall and movement of the normal Toolbox window, live scan/save/reopen, tracking alignment, comfort and performance. The Toolbox no longer follows the wrist. Synthetic replay and seeded Simulator screenshots do not establish physical headset behavior.

Run `./scripts/run-demo.sh --blue --input-smoke` for native window lifecycle and rendered collision/input routing checks. Its console markers are `TOOLBOX_WINDOW_SMOKE_PASS` and `SPATIAL_INPUT_SMOKE_PASS`; these exercise application commands and RealityKit collisions, not physical hand gestures.

Demo presentation flags: `--blue`, `--blackout`, `--aim-left`, `--fixture-near`, `--palm-hidden`, `--show-info`, `--scene-overview`, `--show-preset-editor`, `--show-item-editor`, `--position-tab`, `--transform-gizmo`, `--targeting`, `--retarget-head`. The latter previews a target five seconds after room alignment and leave Save/Cancel open; `--targeting` leaves the pick pending. `--show-item-editor` opens its Info tab; `--position-tab` opens the selected-item Transform window; `--transform-gizmo` shows rotation rings without that window. Demo launches dismiss a restored preset window unless `--show-preset-editor` is requested. These seed reproducible app states, not simulated user gestures. At default pan the whiteboard is lit; the left-pan case shows the speaker's cast shadow.

Interaction captures: [scene breakdown](Screenshots/interaction-scene-overview.png), [selected-item pane](Screenshots/interaction-selected-item.png), [rotation rings](Screenshots/interaction-axis-rings.png), [target Save/Cancel](Screenshots/interaction-target-preview.png), [full item editor](Screenshots/interaction-full-item-editor.png), and [pop-out Transform editor](Screenshots/interaction-item-editor.png). These are native Simulator renders from seeded presentation states, not gesture acceptance evidence.

Earlier retarget captures: [animation recording](Screenshots/fixture-retarget.mp4), [head aim](Screenshots/fixture-retarget-head.png), [mount aim](Screenshots/fixture-retarget-mount.png), [targeting prompt](Screenshots/fixture-targeting.png), [full transform controls](Screenshots/fixture-transform.png).

Room-library captures: [initial room library](Screenshots/room-library.png), [imported rooms and saved setups](Screenshots/room-library-saved.png). Launch `./scripts/run-demo.sh --blue --rooms-tab` to open this toolbox tab. Add `--library-smoke` to run the debug-only native integration check; it writes clearly labelled demo setups and a synthetic mesh replay fixture into DemoLibrary. The synthetic mesh is test data, not a headset scan.

Audit capture: [history and persistent Undo/Redo controls](Screenshots/audit-history.png). Run `./scripts/run-demo.sh --blue --history-smoke` to exercise room-library operations plus history navigation and finish in the History tab. This invokes the same commands as the UI; it does not simulate pinch gestures or keyboard shortcuts.

Earlier screenshots: [blue light](Screenshots/white-room-blue.png), [pan and cast shadow](Screenshots/white-room-aim.png), [blackout](Screenshots/white-room-blackout.png), [toolbox](Screenshots/white-room-toolbox.png), [DMX controls](Screenshots/white-room-controls.png), [position controls](Screenshots/white-room-position.png). Older screenshots document earlier milestones.

`project.yml` is the project source of truth. Regenerate with `xcodegen generate` after adding files. The Environments and FixtureAssets folders must remain folder resources. If XcodeGen emits `BuildableName="VenueVolume.app"`, set it to `Venue Volume.app` in the shared schemes.

References: [Apple dynamic lights and shadows](https://developer.apple.com/videos/play/wwdc2024/10103/), [SpotLightComponent](https://developer.apple.com/documentation/realitykit/spotlightcomponent), [static mesh collisions](https://developer.apple.com/documentation/realitykit/shaperesource/generatestaticmesh(from:)), [input targeting](https://developer.apple.com/documentation/realitykit/inputtargetcomponent), [transform animation](https://developer.apple.com/documentation/realitykit/hastransform/move(to:relativeto:duration:timingfunction:)), [environment lighting weight](https://developer.apple.com/documentation/realitykit/environmentlightingconfigurationcomponent), and [the repository's current movie workflow](../../docs/05%20Operations/mov2splat-review.md).

Capture references: [Applying mesh to real-world surroundings](https://developer.apple.com/documentation/visionOS/applying-mesh-to-real-world-surroundings), [SceneReconstructionProvider](https://developer.apple.com/documentation/arkit/scenereconstructionprovider), and [MeshAnchor](https://developer.apple.com/documentation/arkit/meshanchor).

Toolbox window capture: [normal repositionable window with X and move bar](Screenshots/toolbox-window.png).
