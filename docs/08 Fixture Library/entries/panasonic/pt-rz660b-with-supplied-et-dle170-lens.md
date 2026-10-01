# Panasonic PT-RZ660B with supplied ET-DLE170 lens

- Library state: `ready_for_visualization`
- Identity: model `PT-RZ660B`; laser_projector / WUXGA 1-chip DLP solid-state laser projector, supplied ET-DLE170 lens
- Official source: [https://eu.connect.panasonic.com/gb/en/projectors/pt-rz660](https://eu.connect.panasonic.com/gb/en/projectors/pt-rz660) (accessed 2026-09-30)
- Reference envelope: 0.4980 m W × 0.2000 m H × 0.5808 m D
- Control: Video path by HDMI, SDI, DVI-D, RGB; network/serial control includes Ethernet/PJLink and RS-232. Not DMX-controlled.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/panasonic/pt-rz660b-with-supplied-et-dle170-lens/fixture.json)
- [Blender model](../../../../assets/fixtures/panasonic/pt-rz660b-with-supplied-et-dle170-lens/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/panasonic/pt-rz660b-with-supplied-et-dle170-lens/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/panasonic/pt-rz660b-with-supplied-et-dle170-lens/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- 498 W x 200 H x 580.8 D mm; spec table rounds depth to 581 mm
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `projector` profile with 62 visible meshes and 11,852 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/panasonic/pt-rz660b-with-supplied-et-dle170-lens/validation/detail.json) · [Front](../../../../assets/fixtures/panasonic/pt-rz660b-with-supplied-et-dle170-lens/previews/front.png) · [Side](../../../../assets/fixtures/panasonic/pt-rz660b-with-supplied-et-dle170-lens/previews/side.png) · [Rear](../../../../assets/fixtures/panasonic/pt-rz660b-with-supplied-et-dle170-lens/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/panasonic/pt-rz660b-with-supplied-et-dle170-lens/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/panasonic/pt-rz660b-with-supplied-et-dle170-lens/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
