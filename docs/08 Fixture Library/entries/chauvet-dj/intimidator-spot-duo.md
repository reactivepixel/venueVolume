# CHAUVET DJ Intimidator Spot Duo

- Library state: `ready_for_visualization`
- Identity: model `Intimidator Spot Duo`; moving light / dual moving spot heads on bar
- Official source: [https://www.chauvetdj.com/products/intimidator-spot-duo/](https://www.chauvetdj.com/products/intimidator-spot-duo/) (accessed 2026-10-02)
- Reference envelope: 0.5400 m W × 0.3650 m H × 0.1870 m D
- Control: DMX512; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chauvet-dj/intimidator-spot-duo/fixture.json)
- [Blender model](../../../../assets/fixtures/chauvet-dj/intimidator-spot-duo/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chauvet-dj/intimidator-spot-duo/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chauvet-dj/intimidator-spot-duo/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer publishes assembled dimensions 540 x 187 x 365 mm; long bar dimension is width, vertical envelope is height, and remaining dimension is depth.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `batten` profile with 71 visible meshes and 20,468 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/chauvet-dj/intimidator-spot-duo/validation/detail.json) · [Front](../../../../assets/fixtures/chauvet-dj/intimidator-spot-duo/previews/front.png) · [Side](../../../../assets/fixtures/chauvet-dj/intimidator-spot-duo/previews/side.png) · [Rear](../../../../assets/fixtures/chauvet-dj/intimidator-spot-duo/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/chauvet-dj/intimidator-spot-duo/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chauvet-dj/intimidator-spot-duo/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
