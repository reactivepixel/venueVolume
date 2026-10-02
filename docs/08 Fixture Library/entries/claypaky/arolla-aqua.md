# Claypaky Arolla Aqua

- Library state: `researched`
- Identity: model `CL3027`; moving light / IP66 profile
- Official source: [https://www.claypaky.it/products/arolla-aqua/](https://www.claypaky.it/products/arolla-aqua/) (accessed 2026-10-02)
- Reference envelope: 0.3250 m W × 0.7500 m H × 0.4500 m D
- Control: DMX, Art-Net, RDM, sACN, Wireless DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/claypaky/arolla-aqua/fixture.json)
- [Blender model](../../../../assets/fixtures/claypaky/arolla-aqua/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/claypaky/arolla-aqua/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/claypaky/arolla-aqua/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer states 325 x 450 mm base and 750 mm height with vertical head. Assignment of base axes to width/depth follows the product views; preserve original base spans.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 18,060 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/claypaky/arolla-aqua/validation/detail.json) · [Front](../../../../assets/fixtures/claypaky/arolla-aqua/previews/front.png) · [Side](../../../../assets/fixtures/claypaky/arolla-aqua/previews/side.png) · [Rear](../../../../assets/fixtures/claypaky/arolla-aqua/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/claypaky/arolla-aqua/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/claypaky/arolla-aqua/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
