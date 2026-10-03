# ROBE Lighting iFORTE

- Library state: `researched`
- Identity: model `iFORTE IP65`; moving light / profile / spot
- Official source: [https://www.robe.cz/iforte](https://www.robe.cz/iforte) (accessed 2026-09-30)
- Reference envelope: 0.4800 m W × 0.8370 m H × 0.3350 m D
- Control: DMX512, RDM, Art-Net, sACN, Kling-Net; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/robe-lighting/iforte/fixture.json)
- [Blender model](../../../../assets/fixtures/robe-lighting/iforte/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/robe-lighting/iforte/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/robe-lighting/iforte/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer mechanical specifications, head vertical; use the iFORTE base model, not FS or LTX. Published dimensional sketch gives slightly different heights depending on view; the catalog value of 837 mm is used.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Source describes a vertical-head dimensional pose; modeled horizontal optical-axis pose fits that envelope. Verify pose-specific shape before placement/clearance use.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 18,516 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/robe-lighting/iforte/validation/detail.json) · [Front](../../../../assets/fixtures/robe-lighting/iforte/previews/front.png) · [Side](../../../../assets/fixtures/robe-lighting/iforte/previews/side.png) · [Rear](../../../../assets/fixtures/robe-lighting/iforte/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/robe-lighting/iforte/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/robe-lighting/iforte/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
