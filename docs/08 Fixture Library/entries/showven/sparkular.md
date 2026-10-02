# SHOWVEN SPARKULAR

- Library state: `ready_for_visualization`
- Identity: model `BT01 / BT02`; special effect / cold spark fountain unit
- Official source: [https://www.showven.cn/product/sparkular/](https://www.showven.cn/product/sparkular/) (accessed 2026-10-02)
- Reference envelope: 0.2180 m W × 0.3050 m H × 0.2000 m D
- Control: DMX (2 channels); exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/showven/sparkular/fixture.json)
- [Blender model](../../../../assets/fixtures/showven/sparkular/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/showven/sparkular/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/showven/sparkular/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer page: 200 x 218 x 305 mm; interpreted L x W x H from product viewing orientation.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `spark` profile with 208 visible meshes and 38,144 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/showven/sparkular/validation/detail.json) · [Front](../../../../assets/fixtures/showven/sparkular/previews/front.png) · [Side](../../../../assets/fixtures/showven/sparkular/previews/side.png) · [Rear](../../../../assets/fixtures/showven/sparkular/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/showven/sparkular/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/showven/sparkular/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
