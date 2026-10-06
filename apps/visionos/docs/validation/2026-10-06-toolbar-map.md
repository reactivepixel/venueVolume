# Toolbar-launched Palm Map — v0.2.9

The user reported that neither the automatic wrist reveal nor the palm-map reveal was exposing reliably on the headset. This follow-up changes Palm Map activation to an explicit toolbar action. It does not claim to repair or validate automatic wrist detection.

The bottom toolbar always offers **Wrist toolbox** and **Palm Map**. Opening the map captures a stationary pose in front of the viewer. The map remains visible without a raised palm or ARKit hand-tracking authorization and accepts system indirect pinch/drag input. **Close Palm Map** or **Done** closes it. Venue controls also offer the map button.

Automatic palm-map activation and custom right-hand pinch gating are removed. While the map is open, room/fixture taps and drags, fixture label actions, drop targets, transform handles, and the placement ghost are suppressed. Closing the map restores the previous editing context. Reopening captures a new pose and resets rotation controls. Closing, losing world tracking, changing rooms, or leaving the immersive space cancels an unfinished map gesture; a pending teleport checks its original request before changing the viewpoint.

## Validation

- Agent portable Core and session checks pass; integrated session smoke checks cover explicit opening, absent hand tracking, retained placement context, fresh reopen identity, world-tracking loss, room switches, leaving the space, and closing during blackout.
- Swift syntax parsing and `git diff --check` pass. No app source files were added, so existing Xcode source references remain sufficient.
- Native `--input-smoke` now covers the map blocking room placement, but was not executed on this Linux host.
- Native visionOS SDK compilation and physical headset interaction remain unverified.

On a Vision Pro, open **Palm Map** from the bottom toolbar with both hands lowered, then look around and verify the map stays stationary. Use an ordinary indirect pinch to tap/drag the viewpoint marker. Check Close/Done, reopen from a different viewpoint, and test with hand-tracking permission denied. Confirm the wrist toolbox's explicit toolbar button still recalls the window. During placement, open the map, click outside it, close it, and confirm no fixture was added and placement controls resume.
