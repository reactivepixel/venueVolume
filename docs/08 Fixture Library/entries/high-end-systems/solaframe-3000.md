# High End Systems SolaFrame 3000

- Library state: `researched`
- Identity: model `SolaFrame 3000`; Profile / moving head framing
- Official source: [https://www.etcconnect.com/Products/Legacy/Live-Events-High-End-Systems/Lighting-Fixtures/SolaFrame/3000/Features.aspx](https://www.etcconnect.com/Products/Legacy/Live-Events-High-End-Systems/Lighting-Fixtures/SolaFrame/3000/Features.aspx) (accessed 2026-09-30)
- Reference envelope: 0.4910 m W × 0.8210 m H × 0.3680 m D
- Control: DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/high-end-systems/solaframe-3000/fixture.json)
- [Blender model](../../../../assets/fixtures/high-end-systems/solaframe-3000/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/high-end-systems/solaframe-3000/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/high-end-systems/solaframe-3000/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Overall dimensions are documented; H/W/depth assignment follows the official dimensional drawing.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 17,996 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/high-end-systems/solaframe-3000/validation/detail.json) · [Front](../../../../assets/fixtures/high-end-systems/solaframe-3000/previews/front.png) · [Side](../../../../assets/fixtures/high-end-systems/solaframe-3000/previews/side.png) · [Rear](../../../../assets/fixtures/high-end-systems/solaframe-3000/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/high-end-systems/solaframe-3000/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/high-end-systems/solaframe-3000/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
