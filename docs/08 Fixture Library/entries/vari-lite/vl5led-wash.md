# Vari-Lite VL5LED WASH

- Library state: `researched`
- Identity: model `VL5LED WASH`; Wash / creative moving head wash
- Official source: [https://www.vari-lite.com/global/vl5led-series](https://www.vari-lite.com/global/vl5led-series) (accessed 2026-09-30)
- Reference envelope: 0.3670 m W × 0.5780 m H × 0.3600 m D
- Control: DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/vari-lite/vl5led-wash/fixture.json)
- [Blender model](../../../../assets/fixtures/vari-lite/vl5led-wash/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/vari-lite/vl5led-wash/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/vari-lite/vl5led-wash/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Overall dimensions are documented; width/height/depth assignment follows the official datasheet.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.
- No official product image URL was present in the research CSV.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 89 visible meshes and 22,232 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/vari-lite/vl5led-wash/validation/detail.json) · [Front](../../../../assets/fixtures/vari-lite/vl5led-wash/previews/front.png) · [Side](../../../../assets/fixtures/vari-lite/vl5led-wash/previews/side.png) · [Rear](../../../../assets/fixtures/vari-lite/vl5led-wash/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/vari-lite/vl5led-wash/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/vari-lite/vl5led-wash/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
