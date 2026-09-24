# visionSplat

A small Vision Pro app that places the wearer at the center of a metre-scale Gaussian splat room. It uses **RealityKit's native `GaussianSplatComponent`** on visionOS 27 and renders anisotropic 3D Gaussians with their scale, rotation, opacity, and degree-zero spherical-harmonic color. Head tracking and stereo rendering come from a full `ImmersiveSpace` and `RealityView`.

## Run on Vision Pro

1. On a Mac, install **Xcode 27** with the visionOS 27 SDK and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`). A Vision Pro running **visionOS 27** is required for Gaussian rendering.
2. From this directory, run `xcodegen generate` and open `VisionSplat.xcodeproj`.
3. Select the `VisionSplat` app target, set your development team, and change the example bundle identifier if needed. Select a paired Vision Pro, build, and run.
4. Press **Enter room** in the app window. The bundled 6 × 3 × 6 metre room appears around the starting position, with its floor at the physical floor when at 1× size. Walk naturally to explore. Keep the controls window open to leave, reload, rotate, resize, recenter, or move the view. The system Home control also exits.
5. Press **Open PLY…** to choose a local `.ply`. The app places its bounding-box center at approximately 1.5 metres above the immersive origin, which [Apple places initially at the wearer's feet](https://developer.apple.com/documentation/visionos/adding-3d-content-to-your-app). Prepare scenes in metres with Y up. The move buttons shift the room in 0.5 metre steps along world X/Z axes, letting you explore beyond your physical play area. `Recenter` resets the room translation, size, and rotation; it does not change headset tracking.

The Xcode project is generated deterministically from `project.yml`; the complete Swift sources and bundled PLY are checked in. No external rendering dependency or network access is needed at build time.

## PLY support

The loader accepts ASCII or binary little-endian PLY version 1.0 with a `vertex` element first, including CRLF headers. Properties may be reordered, and unrelated scalar vertex properties are ignored. Required properties: `x`, `y`, `z`, `f_dc_0`–`f_dc_2`, `opacity`, `scale_0`–`scale_2`, and `rot_0`–`rot_3`. These are the standard raw 3DGS training values: log scales, logit opacity, and WXYZ quaternion. The parser normalizes each quaternion, rejects coordinates outside ±1,000,000 metres, and clamps log scales to [−12, 5] before handing them to the native renderer. The renderer applies exponential and sigmoid activation and evaluates degree-zero SH color. Higher SH bands (`f_rest_*`) are ignored; view-dependent color is therefore absent. Import is limited to **250,000 splats and 96 MiB** to bound device memory. File reading and parsing run off the UI actor.

The room is divided into 4 × 4 × 4 spatial cells, each kept in its own native resource (and divided further above 4,096 splats). Cells with fewer than 256 splats receive near-transparent local padding to meet the native renderer's buffer requirements. The current native renderer can cull a component when the viewer enters its bounds. Spatial cells reduce this effect; an individual nearby cell may still disappear. This demo has **no collision geometry**: the visible floor and walls are splats, and the wearer can physically move through them. Use a clear physical play area.

## Validation and platform limits

The repository includes `Resources/demo-room.ply` (6,806 splats) from `../../assets/splats/demo-room.ply`. The bundled sample and source layout were checked on Linux. A standalone macOS parser check uses the shared tiny ASCII, binary, and reordered-binary fixtures, plus malformed CRLF/duplicate/truncated/count/quaternion cases:

```sh
swiftc Sources/SplatPLY.swift Tests/ParserChecks.swift -o /tmp/visionsplat-parser-checks
/tmp/visionsplat-parser-checks ../../assets/splats
```

This host has no Swift, XcodeGen, Xcode, visionOS SDK, simulator, or Vision Pro, so the Swift parser check, Xcode build, and device rendering are **not verified here**. The visionOS 27 simulator may lack the native component, so its UI and import path can be exercised, but the splat view is device-only in this demo. Test on a visionOS 27 device before relying on the rendering path.

API references: [Apple: Gaussian splats on visionOS](https://developer.apple.com/documentation/visionos/gaussian-splats-on-visionos), [GaussianSplatComponent](https://developer.apple.com/documentation/realitykit/gaussiansplatcomponent), [GaussianSplatResource](https://developer.apple.com/documentation/realitykit/gaussiansplatresource), and [Apple engineer's culling discussion](https://developer.apple.com/forums/thread/831298?answerId=891183022). The buffer alignment, sRGB color space, and chunked-resource technique follow the [device-tested SplatStage implementation](https://github.com/ibrews/SplatStage/blob/main/Sources/SplatResourceBuilder.swift).
