# Vari-Lite VL2600 SE WASH

- Library state: `ready_for_visualization`
- Identity: model `VL2600 SE WASH`; moving light / LED wash
- Official source: [https://www.vari-lite.com/global/products/vl2600-wash](https://www.vari-lite.com/global/products/vl2600-wash) (accessed 2026-09-30)
- Reference envelope: 0.4640 m W × 0.7050 m H × 0.3000 m D
- Control: DMX, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/vari-lite/vl2600-se-wash/fixture.json)
- [Blender model](../../../../assets/fixtures/vari-lite/vl2600-se-wash/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/vari-lite/vl2600-se-wash/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/vari-lite/vl2600-se-wash/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- SE revision manufacturer datasheet lists assembled H × W × L as 705 × 464 × 300 mm; excluded packed dimensions.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 73 visible meshes and 19,160 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/vari-lite/vl2600-se-wash/validation/detail.json) · [Front](../../../../assets/fixtures/vari-lite/vl2600-se-wash/previews/front.png) · [Side](../../../../assets/fixtures/vari-lite/vl2600-se-wash/previews/side.png) · [Rear](../../../../assets/fixtures/vari-lite/vl2600-se-wash/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/vari-lite/vl2600-se-wash/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/vari-lite/vl2600-se-wash/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
