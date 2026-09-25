# Venue Volume for visionOS

A native SwiftUI + RealityKit mixed-reality prototype. Virtual fixture cubes remain in the room; a left-palm toolbox provides actions, objects, saved presets, and recent items. Requires visionOS 2 or later.

## Run

Open `VenueVolume.xcodeproj` and choose an Apple Vision Pro destination:

- **VenueVolume** starts an empty session. Select **Enter venue**.
- **VenueVolume Demo** seeds two fixtures and three presets in Simulator and enters the room automatically. Demo changes do not overwrite the saved library.
- On a physical Vision Pro, choose your signing team and allow hand tracking when prompted.

`project.yml` is the project source of truth. After adding app files, regenerate with `xcodegen generate`. If your XcodeGen version writes `BuildableName="VenueVolume.app"` in the schemes, correct it to the configured product name, `Venue Volume.app`.

## Toolbox

Turn your **left palm toward you in your forward viewing area**. The toolbox appears above that palm direction at a comfortable distance. It stays in place during use instead of following small hand movements. Lower or turn away your palm to dismiss it. Opening requires 250 ms of a valid pose; hiding allows an 800 ms grace period for tracking gaps.

Exact eye gaze is private on visionOS. The trigger combines the tracked left wrist/index/little-finger joints with device orientation to approximate looking toward a facing palm. It does not read eye gaze. Physical-device tuning is still required.

The toolbox contains two columns:

- **Library:** independently scrollable actions, presets, and scene objects. Add cube arms the placement grid; select an object to expose its label controls; select a preset to open its editor. The ellipsis menu opens diagnostics or leaves the venue.
- **Recent:** the ten most recently used, unique objects, presets, and actions. Empty sessions display the usage guide. Deleted items are removed. Recents are session-only and survive hiding/revealing the toolbox.

The Simulator-only **Left palm facing me** toggle previews visibility. If hand authorization is denied or tracking cannot start on a headset, an explicit **Show toolbox** fallback remains available. World-placement remains disabled if world tracking fails.

## Objects and presets

- **Add cube:** pick a distance (0.75–4 m), look at the placement grid, and pinch. Cubes are 24 cm, with 16 zeroed channels and automatically allocated nonoverlapping patches.
- **Select:** select a cube or its name. Its label expands above it with **Info** and **Delete**. Selecting another cube collapses the previous selection.
- **Info:** expands the same label upward with read-only name/preset, type, universe, footprint, channel values, world position, and stable UUID. All channel editing lives in the preset editor.
- **Apply preset:** pinch-drag a saved preset from either toolbox column onto the cube face or its label. The highlighted drop target accepts the app's preset identifier; the saved channel values/count are copied to the fixture and linked to that preset. The toolbox stays available during a drag, with a 15-second cancellation timeout.
- **Preset editor:** a separate native window with library navigation, previous/next, New, name, 1–16 channels, and DMX sliders. Draft changes do not affect the scene. Dirty navigation offers Save and Continue, Discard, or Keep Editing; closing/reopening the window retains its draft in session.
- **Save:** persists the preset locally and updates every assigned fixture atomically. **Save as New** creates an independent preset and preserves existing assignments. Use **Apply saved** to assign it to the selected object without a drag.
- **Manage:** Clear channel values zeros the draft; Save commits it. Revert restores the saved version. Delete preset removes it and zeroes/unassigns its fixtures. Clear assignment affects only the selected fixture. Object identity, name, patch, and placement remain instance properties.

Preset validation rejects empty names, values outside 0–255, invalid channel counts, universe overflow, and overlapping fixture footprints. A rejected save/drop leaves the entire prior configuration unchanged. Presets do not encode absolute DMX addresses; each object retains its allocated patch.

## Persistence and mock sync

Normal-mode presets are stored in app UserDefaults as a Codable library. Demo mode uses isolated in-memory examples. Fixtures, room positions, recent items, and unsaved drafts remain session-only. Re-entering a space can change the world origin; no persistent room anchors are implemented.

**Sync configurations** is available in the toolbox and Diagnostics. The complete fixture snapshot includes resolved DMX values, optional preset IDs, counts, revision, and positions. `POST https://venue-volume.invalid/api/v1/dmx/configurations/sync` is intercepted inside the process by a custom URLProtocol. It returns mock HTTP 200 or simulated HTTP 503 without network or lighting output. Edits made during a request remain unsynced.

## Verification

From this directory:

```sh
swift test --package-path Core
./scripts/test-session.sh
xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume \
  -destination 'generic/platform=visionOS Simulator' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume \
  -destination 'generic/platform=visionOS' \
  -derivedDataPath DerivedData-device CODE_SIGNING_ALLOWED=NO build
```

Verified 2026-09-25 with Xcode 27: 18 core tests, the model/session smoke checks, simulator build, and unsigned device build pass. Tests cover atomic assignment/propagation, save-as independence, draft isolation, persistence, deletion/clearing, recency limits, palm debounce, patch conflicts, and mock synchronization.

Simulator screenshots show real rendered UI. The Mac was locked during UI verification, so interactive drag/drop, scrolling, buttons, physical hand detection, real gaze/pinch, and headset comfort are not claimed as tested. The palm-preview and presentation launch flags do not simulate physical hand tracking.

Demo presentation flags (alongside `--demo`): `--show-info`, `--show-recents`, `--show-preset-editor`, and `--palm-hidden` expose repeatable review states.

Headset acceptance:

1. Face left palm toward the wearer; verify reveal, no right-hand activation, tracking-gap grace, and dismissal.
2. Deny hand tracking and verify manual toolbox access. Re-enter after permission changes.
3. Select cubes, toggle Info, delete an object, and confirm its recent item disappears.
4. Drag presets from Library and Recent to cube faces/labels. Cancel a drag and confirm the toolbox eventually dismisses.
5. Change all 16 channels; confirm fixtures stay unchanged until Save. Confirm all assigned objects then update.
6. Save as New, switch presets with unsaved changes, clear/revert, delete, and relaunch to verify persistence.
7. Exercise invalid footprints and sync changes during an in-flight request.

## Screenshots

- [Toolbox with empty Recent guide](Screenshots/toolbox-empty.png)
- [Object Info and recent items](Screenshots/toolbox-object-info.png)
- [Preset editor](Screenshots/preset-editor.png)

The earlier [Figma drawings](../../assets/design/venue-volume/visionos/README.md) describe the previous direct-edit inspector and head-following debug panel; this implementation supersedes that interaction model.
