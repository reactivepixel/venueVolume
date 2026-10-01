# Elation Professional Fuze Wash 500

- Library state: `ready_for_visualization`
- Identity: model `FUZ567`; Moving head / wash
- Official source: [https://www.elationlighting.com/products/fuze-wash-500](https://www.elationlighting.com/products/fuze-wash-500) (accessed 2026-09-30)
- Reference envelope: 0.4079 m W × 0.5505 m H × 0.3895 m D
- Control: DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/elation-professional/fuze-wash-500/fixture.json)
- [Blender model](../../../../assets/fixtures/elation-professional/fuze-wash-500/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/elation-professional/fuze-wash-500/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/elation-professional/fuze-wash-500/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer lists length, width and height with snoot; runtime X/Y/Z uses width/height/length.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 94 visible meshes and 25,556 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/elation-professional/fuze-wash-500/validation/detail.json) · [Front](../../../../assets/fixtures/elation-professional/fuze-wash-500/previews/front.png) · [Side](../../../../assets/fixtures/elation-professional/fuze-wash-500/previews/side.png) · [Rear](../../../../assets/fixtures/elation-professional/fuze-wash-500/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/elation-professional/fuze-wash-500/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/elation-professional/fuze-wash-500/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
