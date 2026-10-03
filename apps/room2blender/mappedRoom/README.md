# mappedRoom

A separate, relightable version of the existing IMG_3153 classroom. Open **Rooms & saved setups → mappedRoom** in the visionOS app. A new blank setup uses the textures; **White model** still overrides them, and saved setups remember that choice. The original classroom and The Fortress are unchanged.

[Review gallery](review/index.html) · [Blender scene](output/mappedRoom.blend) · [self-contained USDZ](output/environment.usdz) · [environment manifest](output/environment.json) · [texture provenance](texture-provenance.json)

## What is mapped

Carpet, sage paint, ivory paint, acoustic ceiling, maple desk and laminate tabletop use small repeating photo-detail tiles extracted from the existing movie reference frames. Reviewed crops exclude objects, trim and strong shadows. The builder removes low-frequency luminance variation, reduces detail contrast and matches the original material's mean linear reflectance. It exports explicit UVs and sRGB base-color textures through USD Preview Surface. Materials stay opaque, rough and non-emissive so dynamic RGB light supplies their illumination and the room mesh supplies depth and shadow occlusion.

This is approximate surface mapping, **not calibrated albedo or camera-projected photogrammetry**. Wall markings, screens, door graphics and other unique landmarks are not reconstructed. Crops, repeat scales and material choices remain reviewed authoring decisions; rebuilds from those inputs are deterministic in geometry/material content. The room's physical dimensions remain unmeasured. USDZ container timestamps and Blender bytes need not be identical across rebuilds; content versioning includes texture hashes and UVs.

## Asset cost and validation

| Property | Original classroom | mappedRoom |
| --- | ---: | ---: |
| Triangles | 18,744 | 18,744 |
| Mesh chunks / materials | 68 / 13 | 68 / 13 |
| Collider boxes / placement surfaces | 96 / 11 | 96 / 11 |
| USDZ bytes | 1,317,759 | 1,893,587 |
| Texture images | 0 | 6 |
| Estimated RGBA8 + mip texture bytes | 0 | 4,194,302 |

The extra USDZ cost is 575,828 bytes (~0.55 MiB). Textures are two 512×512 and four 256×256 PNGs, shared by material, with one base-color sample and no added normal/roughness/opacity images. The memory figure is a conservative format estimate, not device residency. UVs add vertex data but no triangles or draw batches.

[Export validation](output/environment-validation.json) passed OpenUSD validation and a Blender import round trip. [A/B checks](review/comparison.json) compare every mesh's points, indices, normals, extents, plus all colliders, placement surfaces, bounds and spawn; all match. Embedded textures resolve. Materials are opaque and non-emissive. The legacy source package is retained as the baseline without re-exporting it.

## Desktop lighting experiment — 2026-10-03

Blender 5.2.1 / Cycles on NVIDIA RTX 4090, 640×400, 16 samples, fixed seed, one warm render excluded plus three measured renders per cell. Same camera and room geometry, original-material baseline versus photo-mapped materials. Synthetic spotlights cast shadows; fixture meshes are absent from this **room-only offline** experiment. Timing includes submission, rendering and denoising. Rooms were tested sequentially with no concurrent task render.

| Shadow lights | Baseline seconds | mappedRoom seconds |
| ---: | ---: | ---: |
| 0 | 1.055 | 1.104 |
| 1 | 1.285 | 1.340 |
| 2 | 1.407 | 1.478 |
| 4 | 1.516 | 1.575 |
| 8 | 1.655 | 1.640 |
| 16 | 1.736 | 1.727 |
| 32 | 1.866 | 1.831 |
| 64 | 1.933 | 2.013 |


These are **seconds per offline render, not frame times or FPS**. Texture-related differences are small relative to this test's total cost and include timing noise; lower values in some mapped cases are not evidence that textures accelerate rendering. The RGB comparison shows lit textured surfaces and furniture shadows. This does not validate RealityKit import, mobile GPU cost, user comfort or maximum smooth light count.

The app now supports an isolated, repeatable 64-fixture benchmark with 0–64 requested shadow beams, static/moving passes, thermal reporting and JSON export. Read the [native benchmark runbook](../../visionos/docs/MAPPED_ROOM_LIGHTING.md). **No Xcode/Simulator/headset run was possible on this Linux host.** The normal app defaults to eight shadow beams; higher budgets are explicitly experimental until measured on Vision Pro.

## Review views

[Front-left](output/cutaway-front-left.png) · [Front-right](output/cutaway-front-right.png) · [Rear-right](output/cutaway-rear-right.png) · [Rear-left](output/cutaway-rear-left.png) · [Interior](output/interior.png) · [Floor plan](output/floor-plan.png)

[RGB baseline](review/baseline-8-lights.png) · [RGB mappedRoom](review/mappedRoom-8-lights.png) · [Occlusion](output/occlusion.png) · [Occluder hidden for inspection](output/occlusion-reveal.png). Review scenes include inherited test props; the USDZ excludes them.

## Reproduce

From the repository root, using local Blender with USD Python bindings and CUDA for rendering:

```sh
./apps/room2blender/scripts/mapped-room.sh --render --benchmark
```

Without the flags, the script regenerates photo tiles, the Blender scene and USDZ, performs structural parity checks and updates `apps/visionos/VenueVolume/Environments/MappedRoom`. `--render` adds four cutaways/interior/plan/occlusion images; `--benchmark` performs the offline light sweep. `VV_BLENDER=/path/to/blender` selects Blender. Tested with 5.2.1. Keep the mappedRoom folder and adjacent original references together when editing the Blender file; the USDZ includes all required runtime textures.

No video re-extraction, new geometry interpretation, splat training or external image service is needed. The crop recipe is in `../scripts/mapped_textures.py`; modifying it requires renewed visual review. Remote loading remains behind the existing immutable environment manifest/checksum/repository boundary; this milestone adds no server dependency.
