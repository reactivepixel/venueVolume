# Shared Gaussian splat fixtures

`demo-room.ply` is an original synthetic 6 × 3 × 6 metre room with 6,806
anisotropic Gaussians. It has a checkerboard floor and four colored wall panels:
cyan at −Z, orange at +Z, purple at −X, green at +X. Coordinates are Y-up,
with floor center at the origin and an initial eye position of `(0, 1.5, 0)`.
The center is empty so a viewer starts inside the room.

These assets are generated for this repository; no third-party scan or download
is required. They are deliberately small demonstrations, not photogrammetry.

Regenerate from the repository root:

```bash
python3 scripts/splats/generate_demo.py
```

The encoding follows the [original 3DGS exporter](https://github.com/graphdeco-inria/gaussian-splatting/blob/main/scene/gaussian_model.py):
positions, zero normals, DC spherical harmonic color, opacity logits,
logarithmic axis scales, and scalar-first (`w,x,y,z`) quaternion rotation.
Higher-order spherical harmonics are omitted. The room is ASCII; the tiny
fixtures cover ASCII, little-endian binary, and reordered binary properties.
`manifest.json` records expected decoded values.

The three apps package copies of the room for standalone use. After changing
the generator, refresh those copies using the paths in the apps' READMEs.
PLY does not encode a universal up axis, unit, camera, navigable floor, or
collision mesh. Arbitrary trained scenes may need rotation, scale, and recentering.
