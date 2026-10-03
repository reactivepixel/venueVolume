# SGM G-7 Spot

- Library state: `ready_for_visualization`
- Identity: model `G-7 Spot`; moving light / framing profile
- Official source: [https://www.sgmlighting.com/products/architecture/g%C2%B77-spot](https://www.sgmlighting.com/products/architecture/g%C2%B77-spot) (accessed 2026-10-02)
- Reference envelope: 0.3700 m W × 0.6220 m H × 0.4330 m D
- Control: DMX512-A, RDM, CRMX, W-DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/sgm/g-7-spot/fixture.json)
- [Blender model](../../../../assets/fixtures/sgm/g-7-spot/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/sgm/g-7-spot/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/sgm/g-7-spot/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer mechanical specifications; optical-forward neutral pose and detail proportions are image-informed estimates.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 18,124 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/sgm/g-7-spot/validation/detail.json) · [Front](../../../../assets/fixtures/sgm/g-7-spot/previews/front.png) · [Side](../../../../assets/fixtures/sgm/g-7-spot/previews/side.png) · [Rear](../../../../assets/fixtures/sgm/g-7-spot/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/sgm/g-7-spot/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/sgm/g-7-spot/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
