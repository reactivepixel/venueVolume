# CHAUVET Professional Rogue R1X Spot

- Library state: `researched`
- Identity: model `ROGUER1XSPOT`; Moving head / spot
- Official source: [https://chauvetprofessional.com/product/rogue-r1x-spot/](https://chauvetprofessional.com/product/rogue-r1x-spot/) (accessed 2026-09-30)
- Reference envelope: 0.3600 m W × 0.4470 m H × 0.2820 m D
- Control: DMX, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chauvet-professional/rogue-r1x-spot/fixture.json)
- [Blender model](../../../../assets/fixtures/chauvet-professional/rogue-r1x-spot/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chauvet-professional/rogue-r1x-spot/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chauvet-professional/rogue-r1x-spot/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Overall dimensions are documented; W/H/L axis assignment follows the manufacturer product-page order used for this moving head.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 18,060 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/chauvet-professional/rogue-r1x-spot/validation/detail.json) · [Front](../../../../assets/fixtures/chauvet-professional/rogue-r1x-spot/previews/front.png) · [Side](../../../../assets/fixtures/chauvet-professional/rogue-r1x-spot/previews/side.png) · [Rear](../../../../assets/fixtures/chauvet-professional/rogue-r1x-spot/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/chauvet-professional/rogue-r1x-spot/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chauvet-professional/rogue-r1x-spot/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
