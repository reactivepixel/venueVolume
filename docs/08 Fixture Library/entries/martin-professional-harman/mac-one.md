# Martin Professional (HARMAN) MAC One

- Library state: `researched`
- Identity: model `MAC One`; Wash / beam wash moving head
- Official source: [https://www.martin.com/en-US/products/mac-one](https://www.martin.com/en-US/products/mac-one) (accessed 2026-09-30)
- Reference envelope: 0.2540 m W × 0.3490 m H × 0.2200 m D
- Control: DMX, RDM, Art-Net, sACN, Martin P3; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/martin-professional-harman/mac-one/fixture.json)
- [Blender model](../../../../assets/fixtures/martin-professional-harman/mac-one/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/martin-professional-harman/mac-one/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/martin-professional-harman/mac-one/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Maximum envelope is documented; axis assignment follows the official product image and stated yoke width.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 109 visible meshes and 20,808 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/martin-professional-harman/mac-one/validation/detail.json) · [Front](../../../../assets/fixtures/martin-professional-harman/mac-one/previews/front.png) · [Side](../../../../assets/fixtures/martin-professional-harman/mac-one/previews/side.png) · [Rear](../../../../assets/fixtures/martin-professional-harman/mac-one/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/martin-professional-harman/mac-one/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/martin-professional-harman/mac-one/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
