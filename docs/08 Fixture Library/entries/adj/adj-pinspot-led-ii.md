# ADJ ADJ Pinspot LED II

- Library state: `researched`
- Identity: model `PIN222`; pinspot / Static narrow-beam 3 W LED pinspot, exchangeable 3°/12° lens
- Official source: [https://www.adj.com/products/pinspot-led-ii](https://www.adj.com/products/pinspot-led-ii) (accessed 2026-09-30)
- Reference envelope: 0.0990 m W × 0.0610 m H × 0.1840 m D
- Control: Mains powered, local/manual; no DMX
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/adj-pinspot-led-ii/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/adj-pinspot-led-ii/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/adj-pinspot-led-ii/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/adj-pinspot-led-ii/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Manufacturer lists LxWxH but product form indicates 184 mm is the barrel length; mapping to depth follows optical axis, bracket outline not dimensioned.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `pinspot` profile with 8 visible meshes and 2,084 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/adj/adj-pinspot-led-ii/validation/detail.json) · [Front](../../../../assets/fixtures/adj/adj-pinspot-led-ii/previews/front.png) · [Side](../../../../assets/fixtures/adj/adj-pinspot-led-ii/previews/side.png) · [Rear](../../../../assets/fixtures/adj/adj-pinspot-led-ii/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/adj/adj-pinspot-led-ii/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/adj-pinspot-led-ii/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
