# Martin Professional (HARMAN) MAC Ultra Wash

- Library state: `researched`
- Identity: model `MAC Ultra Wash`; Wash / moving head wash
- Official source: [https://www.martin.com/en-US/products/mac-ultra-wash](https://www.martin.com/en-US/products/mac-ultra-wash) (accessed 2026-09-30)
- Reference envelope: 0.5200 m W × 0.8670 m H × 0.6420 m D
- Control: DMX, RDM, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/martin-professional-harman/mac-ultra-wash/fixture.json)
- [Blender model](../../../../assets/fixtures/martin-professional-harman/mac-ultra-wash/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/martin-professional-harman/mac-ultra-wash/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/martin-professional-harman/mac-ultra-wash/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Maximum envelope is documented; H/W/depth assignment follows the official product drawing.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 94 visible meshes and 25,036 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/martin-professional-harman/mac-ultra-wash/validation/detail.json) · [Front](../../../../assets/fixtures/martin-professional-harman/mac-ultra-wash/previews/front.png) · [Side](../../../../assets/fixtures/martin-professional-harman/mac-ultra-wash/previews/side.png) · [Rear](../../../../assets/fixtures/martin-professional-harman/mac-ultra-wash/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/martin-professional-harman/mac-ultra-wash/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/martin-professional-harman/mac-ultra-wash/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
