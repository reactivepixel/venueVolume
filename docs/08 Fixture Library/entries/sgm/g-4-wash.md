# SGM G-4 Wash

- Library state: `ready_for_visualization`
- Identity: model `G-4 Wash`; moving light / pixel wash
- Official source: [https://www.sgmlighting.com/products/g%C2%B74-wash](https://www.sgmlighting.com/products/g%C2%B74-wash) (accessed 2026-10-02)
- Reference envelope: 0.2550 m W × 0.4650 m H × 0.2190 m D
- Control: DMX512-A, RDM, CRMX, W-DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/sgm/g-4-wash/fixture.json)
- [Blender model](../../../../assets/fixtures/sgm/g-4-wash/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/sgm/g-4-wash/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/sgm/g-4-wash/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer mechanical specifications; optical-forward neutral pose and detail proportions are image-informed estimates.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 82 visible meshes and 25,680 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/sgm/g-4-wash/validation/detail.json) · [Front](../../../../assets/fixtures/sgm/g-4-wash/previews/front.png) · [Side](../../../../assets/fixtures/sgm/g-4-wash/previews/side.png) · [Rear](../../../../assets/fixtures/sgm/g-4-wash/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/sgm/g-4-wash/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/sgm/g-4-wash/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
