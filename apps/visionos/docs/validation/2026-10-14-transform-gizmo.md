# Fixture transformation controls — v0.2.16

## Reproduction

`bash apps/visionos/scripts/test-session.sh --interaction-regression` failed before the fix with `TRANSFORM_MODE_FAIL: body hit reset Rotate to Move`. A body interaction called the surface-drag path, which unconditionally selected Move. The lower bar also disabled its segmented picker whenever a drag was active.

The native `--demo --gizmo-smoke` failed with `Move displays handles from the other action`: rotation rings were always enabled, including in Move mode.

## Changes

- Explicit Move/Rotate buttons complete a stale drag and select the requested action. Tapping an already transforming fixture no longer resets its mode. Body sliding is available only in Move.
- Move shows translation handles; Rotate shows rotation rings. Disabled-mode handles cannot start a drag, and a mode change clears outstanding spatial input events.
- Gizmo materials do not read or write scene depth and use the transparent rendering pass at full opacity. Depth bypass alone failed: later opaque draws still covered all Move handles in a blocked/unblocked screenshot comparison. The later pass draws the editing overlay through intersecting room/fixture geometry. A system interaction ray checks the active gizmo independently of foreground geometry, preserving drag coordinates when the initial hit is redirected.
- Floating fixture labels hide during transformation; the context bar keeps the selected name. The bar is wider during transformation, and Move/Rotate labels stay on one line.
- Idle axes use 40% color brightness. The pressed/dragged axis uses full brightness. RealityKit supplies gaze hover highlights; visionOS 26+ groups each axis so its segments highlight together. Material updates occur only when the active axis changes.

Apple references: [UnlitMaterial.readsDepth](https://developer.apple.com/documentation/realitykit/unlitmaterial/readsdepth), [ModelSortGroupComponent](https://developer.apple.com/documentation/realitykit/modelsortgroupcomponent). Runtime verification is necessary in addition to those settings.

## Verification

The session regression now passes Rotate persistence, stale-drag mode changes, actual mount rotation, unchanged channels and Undo/Redo. The native smoke checks both modes, selected-versus-idle material brightness, and picking a handle behind an opaque blocker. It verifies that the ordinary scene ray hits the blocker first, then that the gizmo-aware route picks and begins dragging the obscured handle.

Build/install the Simulator app. Start the screenshot checker before a fresh smoke launch:

```sh
python3 scripts/test-gizmo-render.py SIMULATOR_ID /tmp/gizmo.log /tmp/gizmo
# In another terminal:
xcrun simctl launch --terminate-running-process --console-pty SIMULATOR_ID \
  com.venuevolume.VenueVolume --demo --gizmo-smoke > /tmp/gizmo.log 2>&1
```

The checker requires Pillow and the default demo camera. It compares each mode without and with the blocker, requiring at least 90% of every axis’s unobstructed colored pixels to survive. Captures wait for compositor presentation. A weaker test that merely required some colored pixels missed partial ring occlusion and was replaced. The native console also reports `GIZMO_SMOKE_PASS`.

System gaze-hover appearance and actual wearer pinch accuracy still require physical headset acceptance. Simulator programmatic mode selection does not establish a wearer button-tap pass; Simulator is not exposed through the available native UI automation surfaces.

Final screenshot comparison passes. X/Y/Z pixel counts were 6796/7342/7264 clear versus 6563/7034/6888 blocked for Move; 11523/14279/14129 clear versus 10725/13334/13030 blocked for Rotate. All axes retain over 90% of the clear count. [Move behind the blocker](transform-gizmo/move-blocked.png) and [Rotate behind the blocker](transform-gizmo/rotate-blocked.png) were visually inspected. The context bar displays both action labels and Done without wrapping.

The full session suite and final interaction subset pass. Native output: `GIZMO_SMOKE_PASS exclusiveModes=true overlay=true obstructedHit=true selectedBrightness=true`. The signed headset build passed and its built Info.plist reports 0.2.16. Installation on Chris’s Apple Vision Pro succeeded. After the user reported unlocking it, a console launch failed to connect and a retry timed out; the subsequent device lock query reported `passcodeRequired: true`. Physical runtime, gaze-hover and wearer pinch acceptance remain unverified.
