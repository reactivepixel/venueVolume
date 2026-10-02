# SHOWVEN SPARKULAR mini

- Library state: `ready_for_visualization`
- Identity: model `BT06 / BT07`; special effect / cold spark fountain unit
- Official source: [https://www.showven.cn/product/sparkular-mini/](https://www.showven.cn/product/sparkular-mini/) (accessed 2026-10-02)
- Reference envelope: 0.1800 m W × 0.2280 m H × 0.1680 m D
- Control: DMX (2 channels), wireless remote; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/showven/sparkular-mini/fixture.json)
- [Blender model](../../../../assets/fixtures/showven/sparkular-mini/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/showven/sparkular-mini/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/showven/sparkular-mini/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer sheet: 168 x 180 x 228 mm (L x W x H); normal assembled housing dimensions, packaging excluded.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `spark` profile with 208 visible meshes and 38,144 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/showven/sparkular-mini/validation/detail.json) · [Front](../../../../assets/fixtures/showven/sparkular-mini/previews/front.png) · [Side](../../../../assets/fixtures/showven/sparkular-mini/previews/side.png) · [Rear](../../../../assets/fixtures/showven/sparkular-mini/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/showven/sparkular-mini/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/showven/sparkular-mini/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
