# Gaussian splat viewer demos

Three independent source projects explore the same Gaussian `.ply` environment.
Each packages the original [demo room](../../assets/splats/README.md) and can
load a local PLY. No sample-data account, training run, or downloaded scan is needed.

| App | Target | Start here |
| --- | --- | --- |
| visionSplat | Swift / visionOS 27, Apple Vision Pro; Xcode 27 | [Xcode setup and immersive controls](../../apps/visionSplat/README.md) |
| unitySplat | Unity 2022.3 LTS desktop | [Editor setup, loading, and fly controls](../../apps/unitySplat/README.md) |
| unrealSplat | Unreal Engine 5.6 desktop | [C++ project setup, loading, and fly controls](../../apps/unrealSplat/README.md) |

These are demos with explicit renderer and scene-size limits, described in each
README. Gaussian splats provide appearance, not collision geometry. Navigation
can pass through surfaces. A scene's bounding-box center is a useful initial
viewpoint, but does not identify a navigable room or guarantee an unobstructed
view in an arbitrary scan.

visionSplat uses the native RealityKit Gaussian renderer introduced in visionOS
27. Apple documents that native splat entities can disappear when the viewer
enters their bounds; spatial chunking reduces this limitation but does not
eliminate it. Check near-surface behavior on a physical headset. See
[Apple's engineering guidance](https://developer.apple.com/forums/thread/831298?answerId=891183022).
unrealSplat uses a 640-pixel-wide CPU image and displays at most 30,000 sampled
Gaussians. unitySplat performs projection and depth sorting on the CPU, with
Gaussian falloff and blending on the GPU, and limits imports to 250,000 splats.

## Load a trained scene

1. Produce a standard Gaussian PLY, for example with
   [mov2splat](../../apps/mov2splat/README.md), or use an existing export.
2. Open the target app following its README and first verify the bundled room.
3. Select or enter the local PLY path using the app's loading controls. On
   visionOS, make the file available through the system Files picker.
4. Adjust scene scale and recenter as needed. A trained reconstruction has no
   universal metre scale or up-axis convention; inspect the app's coordinate
   and transform controls if the scene appears tilted or incorrectly sized.

All three loaders target ordinary uncompressed Gaussian PLY, with position,
DC spherical harmonic color, opacity logits, logarithmic scales, and `wxyz`
rotation. ASCII and little-endian binary are the interoperability baseline.
Plain RGB point clouds, compressed/chunked PLY variants, and other splat formats
are not equivalent to this contract. Higher-order color, property flexibility,
and size limits depend on the renderer; consult the app README.

## Validate on target hardware

The implementation host has Python, .NET, and a C++ compiler, but no Xcode,
Unity Editor, Unreal Editor, or Vision Pro. Parser checks and source review on
that host do not establish engine compilation, shader compilation, frame rate,
stereo correctness, or headset comfort. Use this checklist in each target:

- Build the project with the documented engine/SDK version.
- Launch the bundled room. Confirm a visible checkerboard floor, ceiling, and
  four colored wall panels, with the initial camera in the empty center.
- Move and turn. Confirm parallax, translucent Gaussian edges, and changing
  depth order; check both eyes in visionSplat on hardware.
- Load the room again through the file controls, then a trained binary PLY.
- Recenter and change scale. Confirm the scene remains reachable and controls
  respond after loading errors.
- Try a missing file, a non-PLY file, and a truncated PLY. Confirm the app
  reports the problem instead of crashing or hanging.
- Confirm keyboard/mouse capture and release for desktop apps, and immersive
  entry/exit and physical head tracking on Vision Pro.
- Check performance with a representative scan before increasing demo limits.

## Shared assets

Regenerate assets and run their independent format checks from the repository root:

```bash
python3 scripts/splats/generate_demo.py
python3 -B -m unittest discover -s tests/splats -v
```

`assets/splats/manifest.json` contains expected bounds and decoded fixture values.
The three tiny files exercise ASCII, binary, and reordered property handling.
Application parser validation commands are recorded in their READMEs.

Local validation completed for this implementation: shared Python fixture
checks, Unity's standalone .NET parser checks, Unreal's standalone C++ parser
checks, bundled-room byte equality, and project/document link checks. The Swift
parser check is included for macOS but has not been run on this Linux host.
