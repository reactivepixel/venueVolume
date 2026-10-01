# ROBE Lighting Tarrantula

- Library state: `researched`
- Identity: model `Robin Tarrantula RGBA`; moving light / wash beam hybrid
- Official source: [https://www.robe.cz/tarrantula](https://www.robe.cz/tarrantula) (accessed 2026-09-30)
- Reference envelope: 0.5880 m W × 0.6050 m H × 0.5230 m D
- Control: DMX512, RDM, Art-Net, MANet, MANet2, sACN, Kling-Net; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/robe-lighting/tarrantula/fixture.json)
- [Blender model](../../../../assets/fixtures/robe-lighting/tarrantula/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/robe-lighting/tarrantula/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/robe-lighting/tarrantula/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer drawing documents overall envelope labels 588, 605, and 523 mm, but extraction does not make their assignment to model width/height/depth unambiguous. Values are assigned as width x height x depth from the front/side orthographic layout; axis assignment is an estimate, the dimensions themselves are manufacturer-documented.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.
- Source describes a vertical-head dimensional pose; modeled horizontal optical-axis pose fits that envelope. Verify pose-specific shape before placement/clearance use.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 182 visible meshes and 57,108 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/robe-lighting/tarrantula/validation/detail.json) · [Front](../../../../assets/fixtures/robe-lighting/tarrantula/previews/front.png) · [Side](../../../../assets/fixtures/robe-lighting/tarrantula/previews/side.png) · [Rear](../../../../assets/fixtures/robe-lighting/tarrantula/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/robe-lighting/tarrantula/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/robe-lighting/tarrantula/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
