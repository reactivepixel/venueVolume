# ADJ Entour Cyclone

- Library state: `ready_for_visualization`
- Identity: model `ENT550`; atmospherics / DMX axial effect fan
- Official source: [https://www.adj.com/products/entour-cyclone](https://www.adj.com/products/entour-cyclone) (accessed 2026-09-30)
- Reference envelope: 0.3500 m W × 0.4220 m H × 0.1310 m D
- Control: See source-backed protocol list; compatibility and control system are not implemented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/entour-cyclone/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/entour-cyclone/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/entour-cyclone/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/entour-cyclone/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- ADJ manual dimensional drawing gives 350 mm width and 422 mm height in the front elevation, and 131 mm front-to-back in side elevation. The product page's L/W/H naming order is atypical; front/side drawing establishes fixture axes.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `fan` profile with 50 visible meshes and 17,144 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/adj/entour-cyclone/validation/detail.json) · [Front](../../../../assets/fixtures/adj/entour-cyclone/previews/front.png) · [Side](../../../../assets/fixtures/adj/entour-cyclone/previews/side.png) · [Rear](../../../../assets/fixtures/adj/entour-cyclone/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/adj/entour-cyclone/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/entour-cyclone/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
