# Antari F-1 Fazer

- Library state: `ready_for_visualization`
- Identity: model `F-1`; equipment / fog/haze fazer
- Official source: [https://antari.com/products/f-1/](https://antari.com/products/f-1/) (accessed 2026-10-02)
- Reference envelope: 0.2750 m W × 0.3820 m H × 0.6180 m D
- Control: DMX512, manual, timer, optional wireless, optional W-DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/antari/f-1-fazer/fixture.json)
- [Blender model](../../../../assets/fixtures/antari/f-1-fazer/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/antari/f-1-fazer/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/antari/f-1-fazer/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer L/W/H = 618/275/382 mm mapped to depth/width/height.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `hazer` profile with 13 visible meshes and 2,124 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/antari/f-1-fazer/validation/detail.json) · [Front](../../../../assets/fixtures/antari/f-1-fazer/previews/front.png) · [Side](../../../../assets/fixtures/antari/f-1-fazer/previews/side.png) · [Rear](../../../../assets/fixtures/antari/f-1-fazer/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/antari/f-1-fazer/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/antari/f-1-fazer/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
