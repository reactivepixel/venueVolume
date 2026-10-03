# CHAUVET Professional Rogue R2 Wash

- Library state: `researched`
- Identity: model `ROGUER2WASH`; Moving head / wash
- Official source: [https://chauvetprofessional.com/product/rogue-r2-wash/](https://chauvetprofessional.com/product/rogue-r2-wash/) (accessed 2026-09-30)
- Reference envelope: 0.3060 m W × 0.3980 m H × 0.2180 m D
- Control: DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chauvet-professional/rogue-r2-wash/fixture.json)
- [Blender model](../../../../assets/fixtures/chauvet-professional/rogue-r2-wash/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chauvet-professional/rogue-r2-wash/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chauvet-professional/rogue-r2-wash/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Overall dimensions are documented; W/H/L axis assignment follows the manufacturer product-page order used for this moving head.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 128 visible meshes and 38,116 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/chauvet-professional/rogue-r2-wash/validation/detail.json) · [Front](../../../../assets/fixtures/chauvet-professional/rogue-r2-wash/previews/front.png) · [Side](../../../../assets/fixtures/chauvet-professional/rogue-r2-wash/previews/side.png) · [Rear](../../../../assets/fixtures/chauvet-professional/rogue-r2-wash/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/chauvet-professional/rogue-r2-wash/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chauvet-professional/rogue-r2-wash/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
