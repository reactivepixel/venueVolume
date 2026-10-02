# MDG MSe1

- Library state: `ready_for_visualization`
- Identity: model `MSe1`; equipment / weather-resistant fog generator
- Official source: [https://www.mdgfog.com/en/mse1-mse2](https://www.mdgfog.com/en/mse1-mse2) (accessed 2026-10-02)
- Reference envelope: 0.3050 m W × 0.3560 m H × 0.2290 m D
- Control: Manufacturer documents an isolated 20–28 VDC control signal for system integration; no DMX interface is listed. External fluid and gas supply are required dependencies.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/mdg/mse1/fixture.json)
- [Blender model](../../../../assets/fixtures/mdg/mse1/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/mdg/mse1/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/mdg/mse1/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer gives unit dimensions L229 × W305 × H356 mm, mapped to depth/width/height; shipping dimensions 305 × 406 × 736 mm excluded.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `fogger` profile with 11 visible meshes and 1,652 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/mdg/mse1/validation/detail.json) · [Front](../../../../assets/fixtures/mdg/mse1/previews/front.png) · [Side](../../../../assets/fixtures/mdg/mse1/previews/side.png) · [Rear](../../../../assets/fixtures/mdg/mse1/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/mdg/mse1/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/mdg/mse1/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
