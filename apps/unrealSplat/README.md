# unrealSplat

A small Unreal Engine 5.6 game that starts inside a bundled Gaussian-splat room. It uses only C++ and engine modules: there are no authored map, material, shader, or plugin assets to import. The project deliberately uses a CPU renderer for portability. Every visible splat is a depth-sorted, alpha-blended 2D projection of its 3D anisotropic Gaussian covariance; its trained opacity, log scales, quaternion rotation, and degree-zero spherical-harmonic color are used. It is a real Gaussian renderer, with a performance and resolution limit appropriate for a demo rather than a production GPU renderer.

## Open and run

1. Install **Unreal Engine 5.6** with C++ build tools for your operating system.
2. Open `UnrealSplat.uproject` in the Unreal Editor and accept the C++ module rebuild prompt. No import or level setup is needed. If the default engine entry map opens empty in the editor, click **Play**; the game mode creates the camera and loads the bundled room at runtime.
3. The player begins at the center of the 6 × 3 × 6 metre room. Use **W/A/S/D** to fly, **Q/E** to descend/ascend, **right mouse drag** to look, **Shift** to sprint, **F** to return to center, and **+/-** to scale the splat scene. The text box accepts an absolute `.ply` path; click **Load PLY**. **Demo room** reloads the bundled file.

The bundled file is `Content/Splats/demo-room.ply`. `Config/DefaultGame.ini` copies this non-asset directory into packaged builds. Package the game using the standard UE5.6 **Platforms → Package Project** command; the same demo path works from the packaged project. `DefaultEngine.ini` points to the built-in `/Engine/Maps/Entry` and the C++ game mode, so the repository does not depend on a binary `.umap`.

## File and rendering behavior

The loader accepts standard trained Gaussian PLY 1.0 **ASCII** and **binary little-endian** files with `x/y/z`, `f_dc_0..2`, `opacity`, `scale_0..2`, and `rot_0..3` (wxyz). Property order may vary and extra scalar vertex properties are ignored. Input coordinates are metres with +Y up; they are mapped to Unreal's +Z up and centimetres. A new file is centered using its bounding box. Spherical-harmonic coefficients are converted with `color = clamp(0.5 + 0.28209479 * f_dc, 0, 1)`; log scales and opacity logits are exponentiated/sigmoided.

Rendering projects each Gaussian's three rotated scale axes through the current perspective camera, forms a 2 × 2 screen-space covariance, draws the `3σ` ellipse with `opacity × exp(-0.5r²)`, and composites far to near. The display texture is **640 pixels wide** and scales to the viewport. To bound CPU cost, ellipses have a 96-pixel maximum radius and scans over 30,000 Gaussians are evenly sampled; the UI reports both counts. Files larger than 256 MB or one million splats are rejected with a visible error. Transparent splats are depth-sorted against other splats; this demo's empty entry map has no polygonal scene geometry to composite with.

## Parser verification

The decoder has no Unreal dependency and can be checked with a C++17 compiler:

```sh
g++ -std=c++17 -O2 -Wall -Wextra -pedantic tests/ply_reader_test.cpp -o /tmp/unrealsplat-ply-test
/tmp/unrealsplat-ply-test ../../assets/splats/tiny-ascii.ply ../../assets/splats/tiny-binary.ply ../../assets/splats/tiny-reordered-binary.ply Content/Splats/demo-room.ply
```

Run those commands from `apps/unrealSplat`. The test checks valid vertices and Gaussian properties for all four files, plus malformed and CRLF headers. The Unreal project itself needs an installed UE5.6 editor and C++ toolchain to compile and verify visual output; those are not present in this workspace.

Engine API references: [texture region update](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Engine/Engine/UTexture2D/UpdateTextureRegions?application_version=5.5), [HUD canvas drawing](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Engine/AHUD), and [runtime widget construction](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/UMG/Blueprint/UWidgetTree/ConstructWidget?application_version=5.5).
