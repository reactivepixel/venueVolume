# ADJ Focus Spot 6Z

- Library state: `ready_for_visualization`
- Identity: model `FOC635`; moving light / LED zoom spot
- Official source: [https://www.adj.com/products/focus-spot-6z](https://www.adj.com/products/focus-spot-6z) (accessed 2026-10-02)
- Reference envelope: 0.2340 m W × 0.5620 m H × 0.3600 m D
- Control: DMX512, RDM, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/focus-spot-6z/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/focus-spot-6z/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/focus-spot-6z/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/focus-spot-6z/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- ADJ labels assembled dimensions L x W x H = 360 x 234 x 562 mm; long front-back axis is depth, 234 mm is width, and 562 mm is head-upright height.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 18,124 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/adj/focus-spot-6z/validation/detail.json) · [Front](../../../../assets/fixtures/adj/focus-spot-6z/previews/front.png) · [Side](../../../../assets/fixtures/adj/focus-spot-6z/previews/side.png) · [Rear](../../../../assets/fixtures/adj/focus-spot-6z/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/adj/focus-spot-6z/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/focus-spot-6z/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
