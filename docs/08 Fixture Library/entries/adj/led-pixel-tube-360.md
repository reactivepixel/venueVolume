# ADJ LED Pixel Tube 360

- Library state: `ready_for_visualization`
- Identity: model `LED075`; tube / 1 m RGB 360-degree pixel tube, external controller required
- Official source: [https://www.adj.com/products/led-pixel-tube-360](https://www.adj.com/products/led-pixel-tube-360) (accessed 2026-09-30)
- Reference envelope: 1.0000 m W × 0.0500 m H × 0.0500 m D
- Control: External ADJ LED Pixel 4C or 10C controller; tube itself is not directly DMX addressable
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/led-pixel-tube-360/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/led-pixel-tube-360/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/led-pixel-tube-360/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/led-pixel-tube-360/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Manufacturer lists 1000 x 50 x 50 mm.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `tube` profile with 3 visible meshes and 564 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/adj/led-pixel-tube-360/validation/detail.json) · [Front](../../../../assets/fixtures/adj/led-pixel-tube-360/previews/front.png) · [Side](../../../../assets/fixtures/adj/led-pixel-tube-360/previews/side.png) · [Rear](../../../../assets/fixtures/adj/led-pixel-tube-360/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/adj/led-pixel-tube-360/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/led-pixel-tube-360/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
