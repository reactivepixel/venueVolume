# Martin Professional (HARMAN) MAC Aura

- Library state: `researched`
- Identity: model `MAC Aura`; moving light / LED wash
- Official source: [https://www.martin.com/en-US/products/mac-aura](https://www.martin.com/en-US/products/mac-aura) (accessed 2026-09-30)
- Reference envelope: 0.3020 m W × 0.3600 m H × 0.3020 m D
- Control: DMX, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/martin-professional-harman/mac-aura/fixture.json)
- [Blender model](../../../../assets/fixtures/martin-professional-harman/mac-aura/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/martin-professional-harman/mac-aura/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/martin-professional-harman/mac-aura/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Overall width and length across yoke plus vertical height with head straight up from manufacturer product specifications.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Source describes a vertical-head dimensional pose; modeled horizontal optical-axis pose fits that envelope. Verify pose-specific shape before placement/clearance use.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 164 visible meshes and 39,828 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/martin-professional-harman/mac-aura/validation/detail.json) · [Front](../../../../assets/fixtures/martin-professional-harman/mac-aura/previews/front.png) · [Side](../../../../assets/fixtures/martin-professional-harman/mac-aura/previews/side.png) · [Rear](../../../../assets/fixtures/martin-professional-harman/mac-aura/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/martin-professional-harman/mac-aura/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/martin-professional-harman/mac-aura/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
