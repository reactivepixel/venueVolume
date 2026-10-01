# Robert Juliat Roxie2 1166-2 WW

- Library state: `ready_for_visualization`
- Identity: model `1166-2 WW`; followspot / 300 W LED manually operated followspot, warm white
- Official source: [https://www.robertjuliat.com/followspots/roxie.html](https://www.robertjuliat.com/followspots/roxie.html) (accessed 2026-09-30)
- Reference envelope: 0.3210 m W × 0.3870 m H × 1.0450 m D
- Control: Operator manually aims pan/tilt; local controls and optional DMX dimmer/strobe only
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/robert-juliat/roxie2-1166-2-ww/fixture.json)
- [Blender model](../../../../assets/fixtures/robert-juliat/roxie2-1166-2-ww/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/robert-juliat/roxie2-1166-2-ww/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/robert-juliat/roxie2-1166-2-ww/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Exact 1166-2 WW dimensional specification drawing; long dimension is optical-axis length.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `followspot` profile with 16 visible meshes and 5,844 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/robert-juliat/roxie2-1166-2-ww/validation/detail.json) · [Front](../../../../assets/fixtures/robert-juliat/roxie2-1166-2-ww/previews/front.png) · [Side](../../../../assets/fixtures/robert-juliat/roxie2-1166-2-ww/previews/side.png) · [Rear](../../../../assets/fixtures/robert-juliat/roxie2-1166-2-ww/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/robert-juliat/roxie2-1166-2-ww/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/robert-juliat/roxie2-1166-2-ww/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
