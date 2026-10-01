# Claypaky Volero Wave

- Library state: `ready_for_visualization`
- Identity: model `CL3023`; LED bar effect / eight-head moving batten
- Official source: [https://www.claypaky.it/products/volero-wave/](https://www.claypaky.it/products/volero-wave/) (accessed 2026-09-30)
- Reference envelope: 1.0000 m W × 0.3290 m H × 0.1820 m D
- Control: DMX512, RDM, Art-Net, sACN, WebServer; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/claypaky/volero-wave/fixture.json)
- [Blender model](../../../../assets/fixtures/claypaky/volero-wave/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/claypaky/volero-wave/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/claypaky/volero-wave/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Product page lists size 1000 x 329 x 182 mm; long axis treated as width for horizontal bar pose.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `batten` profile with 141 visible meshes and 29,628 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/claypaky/volero-wave/validation/detail.json) · [Front](../../../../assets/fixtures/claypaky/volero-wave/previews/front.png) · [Side](../../../../assets/fixtures/claypaky/volero-wave/previews/side.png) · [Rear](../../../../assets/fixtures/claypaky/volero-wave/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/claypaky/volero-wave/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/claypaky/volero-wave/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
