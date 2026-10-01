# Martin Professional (HARMAN) Atomic 3000 LED

- Library state: `researched`
- Identity: model `Atomic 3000 LED`; Strobe / blinder / LED strobe
- Official source: [https://www.martin.com/en-US/products/atomic-3000-led/](https://www.martin.com/en-US/products/atomic-3000-led/) (accessed 2026-09-30)
- Reference envelope: 0.4250 m W × 0.2450 m H × 0.2400 m D
- Control: DMX, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/martin-professional-harman/atomic-3000-led/fixture.json)
- [Blender model](../../../../assets/fixtures/martin-professional-harman/atomic-3000-led/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/martin-professional-harman/atomic-3000-led/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/martin-professional-harman/atomic-3000-led/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Overall dimensions are documented; H/W/depth assignment follows product imagery and the manufacturer technical page.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `strobe` profile with 111 visible meshes and 20,884 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/martin-professional-harman/atomic-3000-led/validation/detail.json) · [Front](../../../../assets/fixtures/martin-professional-harman/atomic-3000-led/previews/front.png) · [Side](../../../../assets/fixtures/martin-professional-harman/atomic-3000-led/previews/side.png) · [Rear](../../../../assets/fixtures/martin-professional-harman/atomic-3000-led/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/martin-professional-harman/atomic-3000-led/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/martin-professional-harman/atomic-3000-led/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
