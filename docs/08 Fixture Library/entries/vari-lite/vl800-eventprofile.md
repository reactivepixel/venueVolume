# Vari-Lite VL800 EVENTPROFILE

- Library state: `ready_for_visualization`
- Identity: model `VL800 EVENTPROFILE`; moving light / LED profile
- Official source: [https://www.vari-lite.com/global/products/vl800-eventprofile](https://www.vari-lite.com/global/products/vl800-eventprofile) (accessed 2026-09-30)
- Reference envelope: 0.3750 m W × 0.6240 m H × 0.4080 m D
- Control: DMX, RDM, Art-Net; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/vari-lite/vl800-eventprofile/fixture.json)
- [Blender model](../../../../assets/fixtures/vari-lite/vl800-eventprofile/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/vari-lite/vl800-eventprofile/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/vari-lite/vl800-eventprofile/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer specification sheet gives assembled physical extents; excludes packed dimensions.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 18,580 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/vari-lite/vl800-eventprofile/validation/detail.json) · [Front](../../../../assets/fixtures/vari-lite/vl800-eventprofile/previews/front.png) · [Side](../../../../assets/fixtures/vari-lite/vl800-eventprofile/previews/side.png) · [Rear](../../../../assets/fixtures/vari-lite/vl800-eventprofile/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/vari-lite/vl800-eventprofile/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/vari-lite/vl800-eventprofile/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
