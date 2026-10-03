# Claypaky Sinfonya Profile 600

- Library state: `researched`
- Identity: model `CL3018`; moving light / LED profile
- Official source: [https://www.claypaky.it/products/sinfonya-profile-600/](https://www.claypaky.it/products/sinfonya-profile-600/) (accessed 2026-09-30)
- Reference envelope: 0.4250 m W × 0.7960 m H × 0.4170 m D
- Control: DMX, Art-Net, sACN, RDM, CRMX (optional), WebServer; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/claypaky/sinfonya-profile-600/fixture.json)
- [Blender model](../../../../assets/fixtures/claypaky/sinfonya-profile-600/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/claypaky/sinfonya-profile-600/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/claypaky/sinfonya-profile-600/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Claypaky product page lists 425 x 417 mm base dimensions and 796 mm height with vertical head.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Source describes a vertical-head dimensional pose; modeled horizontal optical-axis pose fits that envelope. Verify pose-specific shape before placement/clearance use.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 18,516 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/claypaky/sinfonya-profile-600/validation/detail.json) · [Front](../../../../assets/fixtures/claypaky/sinfonya-profile-600/previews/front.png) · [Side](../../../../assets/fixtures/claypaky/sinfonya-profile-600/previews/side.png) · [Rear](../../../../assets/fixtures/claypaky/sinfonya-profile-600/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/claypaky/sinfonya-profile-600/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/claypaky/sinfonya-profile-600/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
