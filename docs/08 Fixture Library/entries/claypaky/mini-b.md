# Claypaky Mini-B

- Library state: `researched`
- Identity: model `CL3005`; moving light / compact LED wash beam
- Official source: [https://www.claypaky.it/products/mini-b/](https://www.claypaky.it/products/mini-b/) (accessed 2026-09-30)
- Reference envelope: 0.2200 m W × 0.3460 m H × 0.1860 m D
- Control: DMX512, RDM, Art-Net, sACN, WebServer; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/claypaky/mini-b/fixture.json)
- [Blender model](../../../../assets/fixtures/claypaky/mini-b/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/claypaky/mini-b/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/claypaky/mini-b/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Product page gives base dimensions 186 x 220 mm and height 346 mm with head vertical; corresponding leaflet gives overall size 224 x 186 x 340 mm.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Source describes a vertical-head dimensional pose; modeled horizontal optical-axis pose fits that envelope. Verify pose-specific shape before placement/clearance use.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 92 visible meshes and 25,540 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/claypaky/mini-b/validation/detail.json) · [Front](../../../../assets/fixtures/claypaky/mini-b/previews/front.png) · [Side](../../../../assets/fixtures/claypaky/mini-b/previews/side.png) · [Rear](../../../../assets/fixtures/claypaky/mini-b/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/claypaky/mini-b/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/claypaky/mini-b/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
