# CHAUVET DJ High Performance Fog Fluid (FJU) Gallon Jug

- Library state: `researched`
- Identity: model `FJU`; atmospherics / sealed manufacturer-approved water-based fog-fluid container
- Official source: [https://www.chauvetdj.com/products/fog-juice-gallon/](https://www.chauvetdj.com/products/fog-juice-gallon/) (accessed 2026-09-30)
- Reference envelope: 0.1550 m W × 0.3000 m H × 0.1550 m D
- Control: See source-backed protocol list; compatibility and control system are not implemented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chauvet-dj/high-performance-fog-fluid-fju-gallon-jug/fixture.json)
- [Blender model](../../../../assets/fixtures/chauvet-dj/high-performance-fog-fluid-fju-gallon-jug/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chauvet-dj/high-performance-fog-fluid-fju-gallon-jug/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chauvet-dj/high-performance-fog-fluid-fju-gallon-jug/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- CHAUVET lists dimensions 155 x 155 x 300 mm without axis labels; bottle photo supports upright height on the 300 mm axis and equal 155 mm base axes.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `fluid_container` profile with 30 visible meshes and 1,672 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/chauvet-dj/high-performance-fog-fluid-fju-gallon-jug/validation/detail.json) · [Front](../../../../assets/fixtures/chauvet-dj/high-performance-fog-fluid-fju-gallon-jug/previews/front.png) · [Side](../../../../assets/fixtures/chauvet-dj/high-performance-fog-fluid-fju-gallon-jug/previews/side.png) · [Rear](../../../../assets/fixtures/chauvet-dj/high-performance-fog-fluid-fju-gallon-jug/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/chauvet-dj/high-performance-fog-fluid-fju-gallon-jug/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chauvet-dj/high-performance-fog-fluid-fju-gallon-jug/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
