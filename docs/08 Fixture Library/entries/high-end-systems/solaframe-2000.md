# High End Systems SolaFrame 2000

- Library state: `researched`
- Identity: model `SolaFrame 2000`; moving light / LED framing profile
- Official source: [https://www.etcconnect.com/Products/Legacy/Live-Events-High-End-Systems/Lighting-Fixtures/SolaFrame/2000/Features.aspx](https://www.etcconnect.com/Products/Legacy/Live-Events-High-End-Systems/Lighting-Fixtures/SolaFrame/2000/Features.aspx) (accessed 2026-09-30)
- Reference envelope: 0.4750 m W × 0.8380 m H × 0.3200 m D
- Control: DMX, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/high-end-systems/solaframe-2000/fixture.json)
- [Blender model](../../../../assets/fixtures/high-end-systems/solaframe-2000/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/high-end-systems/solaframe-2000/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/high-end-systems/solaframe-2000/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer Rev B datasheet, overall assembled fixture dimensions excluding mounting hardware. Power is 864 W at 120 V input.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Source describes a vertical-head dimensional pose; modeled horizontal optical-axis pose fits that envelope. Verify pose-specific shape before placement/clearance use.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 18,516 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/high-end-systems/solaframe-2000/validation/detail.json) · [Front](../../../../assets/fixtures/high-end-systems/solaframe-2000/previews/front.png) · [Side](../../../../assets/fixtures/high-end-systems/solaframe-2000/previews/side.png) · [Rear](../../../../assets/fixtures/high-end-systems/solaframe-2000/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/high-end-systems/solaframe-2000/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/high-end-systems/solaframe-2000/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
