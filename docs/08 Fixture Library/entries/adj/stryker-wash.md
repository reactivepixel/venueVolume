# ADJ STRYKER WASH

- Library state: `ready_for_visualization`
- Identity: model `STR100`; Moving head / wash
- Official source: [https://www.adj.com/products/stryker-wash](https://www.adj.com/products/stryker-wash) (accessed 2026-09-30)
- Reference envelope: 0.3240 m W × 0.3990 m H × 0.2220 m D
- Control: DMX-512; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/stryker-wash/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/stryker-wash/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/stryker-wash/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/stryker-wash/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer specifies L x W x H; runtime X/Y/Z uses W/H/L.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 128 visible meshes and 38,116 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/adj/stryker-wash/validation/detail.json) · [Front](../../../../assets/fixtures/adj/stryker-wash/previews/front.png) · [Side](../../../../assets/fixtures/adj/stryker-wash/previews/side.png) · [Rear](../../../../assets/fixtures/adj/stryker-wash/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/adj/stryker-wash/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/stryker-wash/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
