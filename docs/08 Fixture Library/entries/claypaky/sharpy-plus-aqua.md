# Claypaky Sharpy Plus Aqua

- Library state: `ready_for_visualization`
- Identity: model `CD3002`; Moving head / IP66 hybrid beam spot
- Official source: [https://www.claypaky.it/products/sharpy-plus-aqua/](https://www.claypaky.it/products/sharpy-plus-aqua/) (accessed 2026-09-30)
- Reference envelope: 0.4200 m W × 0.7310 m H × 0.3360 m D
- Control: DMX, Art-Net, RDM, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/claypaky/sharpy-plus-aqua/fixture.json)
- [Blender model](../../../../assets/fixtures/claypaky/sharpy-plus-aqua/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/claypaky/sharpy-plus-aqua/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/claypaky/sharpy-plus-aqua/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer specifies L x W x H; runtime X/Y/Z uses W/H/L.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 17,996 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/claypaky/sharpy-plus-aqua/validation/detail.json) · [Front](../../../../assets/fixtures/claypaky/sharpy-plus-aqua/previews/front.png) · [Side](../../../../assets/fixtures/claypaky/sharpy-plus-aqua/previews/side.png) · [Rear](../../../../assets/fixtures/claypaky/sharpy-plus-aqua/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/claypaky/sharpy-plus-aqua/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/claypaky/sharpy-plus-aqua/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
