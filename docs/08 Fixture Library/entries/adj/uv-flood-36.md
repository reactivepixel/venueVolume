# ADJ UV Flood 36

- Library state: `researched`
- Identity: model `UVF021`; uv / 12 x 3 W 395–400 nm dedicated LED blacklight flood
- Official source: [https://www.adj.com/products/uv-flood-36](https://www.adj.com/products/uv-flood-36) (accessed 2026-09-30)
- Reference envelope: 0.3000 m W × 0.2350 m H × 0.1150 m D
- Control: DMX, manual dimmer or sound-active
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/uv-flood-36/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/uv-flood-36/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/uv-flood-36/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/uv-flood-36/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Manufacturer LxWxH values; front-facing pose inferred from 4-column x 3-row aperture arrangement in product image, not a dimensional drawing.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `uv` profile with 29 visible meshes and 5,452 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/adj/uv-flood-36/validation/detail.json) · [Front](../../../../assets/fixtures/adj/uv-flood-36/previews/front.png) · [Side](../../../../assets/fixtures/adj/uv-flood-36/previews/side.png) · [Rear](../../../../assets/fixtures/adj/uv-flood-36/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/adj/uv-flood-36/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/uv-flood-36/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
