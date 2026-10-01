# Doughty Engineering Twenty Clamp

- Library state: `ready_for_visualization`
- Identity: model `T58400`; lighting_clamp / pressure die-cast aluminium lightweight lantern clamp for 48-51 mm tube
- Official source: [https://doughty-usa.com/products/twenty-clamp/](https://doughty-usa.com/products/twenty-clamp/) (accessed 2026-09-30)
- Reference envelope: 0.1010 m W × 0.0615 m H × 0.0280 m D
- Control: Passive mechanical clamp; no DMX, network, or electrical connection.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/doughty-engineering/twenty-clamp/fixture.json)
- [Blender model](../../../../assets/fixtures/doughty-engineering/twenty-clamp/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/doughty-engineering/twenty-clamp/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/doughty-engineering/twenty-clamp/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- 101 L x 61.5 H x 28 W mm per manufacturer's dimension drawing; 48-51 mm tube fit range
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `clamp` profile with 5 visible meshes and 1,612 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/doughty-engineering/twenty-clamp/validation/detail.json) · [Front](../../../../assets/fixtures/doughty-engineering/twenty-clamp/previews/front.png) · [Side](../../../../assets/fixtures/doughty-engineering/twenty-clamp/previews/side.png) · [Rear](../../../../assets/fixtures/doughty-engineering/twenty-clamp/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/doughty-engineering/twenty-clamp/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/doughty-engineering/twenty-clamp/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
