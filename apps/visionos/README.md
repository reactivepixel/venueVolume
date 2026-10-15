# Venue Volume for visionOS

A SwiftUI and RealityKit workspace for room-scale fixture placement, palette/phaser programming, cue playback and venue preparation. Requires visionOS 2+.

## Build and run

Open `VenueVolume.xcodeproj` in Xcode. Choose **VenueVolume** for the venue chooser or **VenueVolume Demo** for a populated demonstration. Pair/unlock the headset and select your signing team. Allow hand tracking for the wrist Toolbox and navigation. Regenerate the project after moving sources with `xcodegen generate --spec project.yml`.

```sh
xcodebuild -project VenueVolume.xcodeproj -scheme VenueVolume \
  -sdk xrsimulator -destination 'generic/platform=visionOS Simulator' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
```

## RoomScan

The [roomScan pipeline](../roomScan/README.md) turns movie references and reviewed geometry into a Blender scene, USDZ and environment manifest. Import the bundle in the room library, or add it under `VenueVolume/Environments` and register its manifest in `BundledEnvironmentRepository`. The manifest supplies meter scale, spawn, colliders and fixture placement surfaces. Existing local native mesh scans are also supported.

## Interaction

Looking at the left wrist reveals the **Toolbox**. It contains fixture inventory, the selected fixture list, placement, Undo/Redo and the bundle version. Background selection clears the fixture selection; multiple selected fixtures can be named as a group.

The lower **context bar** collapses to an ellipsis with no selection. Expanding it provides Toolbox, Undo/Redo, room positioning and previous/next cue controls. Room positioning opens the isometric map, where obstructed destinations are marked before teleporting.

Placement commits the head-centered ghost position. A selected fixture can use Move arrows or Rotate rings; only the chosen mode is interactive. Handles render through room geometry and dim when idle. Pressed axes and native gaze hover highlight the active control.

The palette editor follows the fixture selection. Static attributes and Dynamic phaser steps preview on the actual fixtures and a flat diagram. Playback pause freezes both. Cues run from **01–255**; edits save to the current cue, with a specific-cue destination available. Target Fixture(s) solves aiming channels for the selected room location. Reusable palettes, step references, macros and cue snapshots keep their separate responsibilities.

## Source organization

- `Models/VenueModel.swift`: observed session state, initialization, selection and fixture placement.
- `Models/VenueModel+Palettes.swift`: palette library, live preview and targeting.
- `Models/VenueModel+Cues.swift`: cue storage, recall and programmer selection.
- `Models/VenueModel+Transforms.swift`: fixture mount gestures and surface placement.
- `Models/VenueModel+History.swift`: gesture transactions and Undo/Redo.
- `Models/VenueModel+Library.swift`: room loading, imports and setup handoff.
- `Models/VenueModel+Touring.swift`: inventory, groups, configurations and touring edits.
- `Models/VenueModel+Macros.swift`: macro preflight and application.
- `Spatial/`: RealityKit rendering, tracking, input routing and native room scanning.
- `Views/`: launch, Toolbox, room placement and palette windows, plus their embedded editors.
- `Core/Sources/VenueVolumeCore/`: platform-independent value models, validation, persistence and lighting calculations.

Views invoke session operations rather than editing persisted structures directly. A gesture owns one history transaction. Spatial rendering consumes resolved fixture output; it does not author palette or cue state. Keep file-private helpers private; cross-file session extension operations are internal to the application module.

The abandoned pop-out fixture-info state, palette drag connector, unused placement pane, mock sync client, diagnostics window, benchmark and embedded smoke harnesses have been removed. Tour previews commit cue changes with their assignments and retain pending programmer edits. Macros flush edits before application; phaser rendering preserves fixture-body drag eligibility. Pinned cue sources are validated before playback.

Automated test targets and scripts were removed at the owner's request. Historical validation reports describe earlier builds; current verification is by compilation and direct runtime review. Headset availability is required to verify spatial interaction on device.

`venuevolume://place?version=1&loadout=<UUID>&fixture=<UUID>` opens an existing native fixture placement. Browser-to-native data transfer is not implemented.
