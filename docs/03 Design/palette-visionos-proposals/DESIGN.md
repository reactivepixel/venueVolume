# Native visionOS palette proposals

Visual thesis: legible white typography on native adaptive glass, with comfortable eye targets and a single spatial focus instead of a full desktop workspace.

Content plan: selected palette and fixtures; tap-tempo and numbered steps; flat output preview and line graph; selected step with presaved configurations and recents; a selection-only context ornament for update/apply.

Interaction thesis: gaze highlight identifies a target, pinch activates it; repeated pinch/tap on BPM sets tempo; step selection discloses the inspector; procedural pool swatches and the four-beam preview animate together and stop for Reduce Motion. A 4/4 shortcut maps one beat per step, while preserving a distinct measure concept for production.

11 Native composer — Apple system glass, adjacent step disclosure, familiar buttons and a context ornament. Native conventions are the implementation target, not a claim of completed accessibility or headset validation.
12 Spatial console — grandMA3-inspired pool numbering and programmer layers, with a native horizontal step drawer and larger targets.
13 Preview stage — Alan Cooper-inspired goal-first composition, large output and rhythm/step controls directly beneath it.
14 Step studio — Don Norman-inspired explicit action, selected source, timing and result; inspector becomes the main editing surface, library stays beside it.
15 Light score — Bret Victor-inspired experimental, coupled fixture score and tempo with a floating step lens.

Original proposals; not work by or endorsed by the named designers. These are a separate native visionOS design harness, not a replacement for the shipping app. The app's existing wrist Palettes button continues to launch its current editor; the chosen proposal would use the same entry route.

Sources: [Apple spatial layout](https://developer.apple.com/design/human-interface-guidelines/spatial-layout/), [ornaments](https://developer.apple.com/design/human-interface-guidelines/ornaments), [Design for spatial user interfaces](https://developer.apple.com/videos/play/wwdc2023/10076/). Use native glass, avoid opaque window backgrounds, keep relevant controls near the center, and give targets at least 60 points of space. At 16 steps the orbital centers remain at least 60 points apart. The screenshots show eight steps, step 3 selected, 120 BPM, two bars in 4/4 and four selected fixtures. Refer to previous proposal research for MA timing semantics.

## Capture and validation

Built as a separate native SwiftUI visionOS application with Xcode 27, launched in the Apple Vision Pro simulator. Five screenshots were inspected and layouts with clipping were repaired. Images are simulator captures cropped to the editor and its context ornament, with no generated or composited controls. Native glass is allowed to respond to the simulator room. These are proposal states, not headset-tested production screens.

Tap tempo, step-count slider, bar shortcuts, numbered-step selection, pattern choice, pool presentation and preview playback have prototype handlers. Save/apply buttons are visual placeholders. Step templates show the proposed quick-setup workflow; the harness does not implement the full palette/phaser data model, production storage, accessibility scaling, or fixture control.

The installed Xcode is missing its optional Metal toolchain. `Reference/Swatches.metal` preserves the proposed shader; the harness uses the same procedural field calculations in SwiftUI Canvas so the actual native screen can be captured without downloading a compiler. Swatches animate with preview playback and stop for Reduce Motion.

Generate/build:

```sh
xcodegen generate --spec 'docs/03 Design/palette-visionos-proposals/project.yml'
xcodebuild -project 'docs/03 Design/palette-visionos-proposals/PaletteProposals.xcodeproj' -scheme PaletteProposals -sdk xrsimulator -destination 'generic/platform=visionOS Simulator' -derivedDataPath 'docs/03 Design/palette-visionos-proposals/DerivedData' build
```

Install the resulting `PaletteProposals.app` in a visionOS simulator. Launch bundle `com.venuevolume.PaletteProposals` with `--proposal 11` through `--proposal 15`. `capture.py` records and crops the current simulator view; update its simulator ID and crop bounds when using another simulator/viewpoint. Generated project, build products and full-room captures are ignored.
