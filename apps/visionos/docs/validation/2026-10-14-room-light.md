# Room ambient brightness — v0.2.14

The Room light control previously changed `EnvironmentLightingConfigurationComponent` on the scene container. Native Simulator renders at 0% and 100% were identical (sampled room luminance 54.01 at both ends). Moving that component to the room meshes also produced no visible change, despite confirming the slider reached the mesh components and the room used physically based materials.

The room now receives an explicit image based ambient light, blending a black environment with a soft white hemisphere. Only room meshes receive this source. Fixture spotlights retain their intensity, color, angles, attenuation and phaser programming. The UI shows the percentage and explains the control's scope.

## Reproduction and regression

Build with Xcode for visionOS Simulator, install, and start the capture script before launching a fresh demo session:

```sh
python3 scripts/test-room-light-render.py SIMULATOR_ID /tmp/room-light.log /tmp/room-light
# In a second terminal:
xcrun simctl launch --terminate-running-process --console-pty SIMULATOR_ID \
  com.venuevolume.VenueVolume --demo --room-light-smoke > /tmp/room-light.log 2>&1
```

Use a fresh log path. The script requires Pillow. The demo temporarily blacks out fixtures for two room screenshots, then restores fixture output and compares actual Spotlight components across the slider extremes. It also compares fixtures, rendered channels, palettes and cues, and verifies room receiver assignments.

Simulator 27 result: room luminance at 0% = 0.00; at 100% = 116.62; difference = 116.62 (required minimum 15). The original implementation fails this same screenshot check. Native runtime result:

```
ROOM_LIGHT_RENDER_PASS
ROOM_LIGHT_SMOKE_PASS fixtureProgrammingUnchanged=true fixtureEmittersUnchanged=true roomOnly=true
```

Both screenshots were visually inspected: the room is dark at zero and visibly illuminated at full brightness. This is a rendering regression check, not calibrated photometry. Physical slider gesture comfort and room-specific brightness preferences remain wearer acceptance checks.

The full session suite passes, including programming, cue, selection, Undo/Redo and persistence checks. Unsigned Simulator and signed device builds pass.

Render evidence: [0% ambient](room-light/ambient-zero.png), [100% ambient](room-light/ambient-full.png). Fixture blackout is enabled only for these comparison captures.

The signed v0.2.14 bundle reports `CFBundleShortVersionString = 0.2.14` and installs successfully on Chris's Apple Vision Pro (00008112-001619923CC1A01E). At this checkpoint the device requires its passcode; physical runtime checks for room ambience and the prior phaser/placement fixes remain pending unlock. Simulator evidence does not establish a physical device pass.
