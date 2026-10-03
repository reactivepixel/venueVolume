# Robert Juliat Lutin 306LPC

- Library state: `ready_for_visualization`
- Identity: model `306LPC`; pc / 150 mm plano-convex theatre luminaire, 1 kW
- Official source: [https://www.robertjuliat.com/singlelenslum/lutin.html](https://www.robertjuliat.com/singlelenslum/lutin.html) (accessed 2026-09-30)
- Reference envelope: 0.3000 m W × 0.3850 m H × 0.4300 m D
- Control: Mains-powered tungsten fixture; dimmer compatibility not transcribed from cited specification
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/robert-juliat/lutin-306lpc/fixture.json)
- [Blender model](../../../../assets/fixtures/robert-juliat/lutin-306lpc/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/robert-juliat/lutin-306lpc/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/robert-juliat/lutin-306lpc/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Manufacturer drawing for exact 306LPC variant.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `pc` profile with 36 visible meshes and 7,928 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/robert-juliat/lutin-306lpc/validation/detail.json) · [Front](../../../../assets/fixtures/robert-juliat/lutin-306lpc/previews/front.png) · [Side](../../../../assets/fixtures/robert-juliat/lutin-306lpc/previews/side.png) · [Rear](../../../../assets/fixtures/robert-juliat/lutin-306lpc/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/robert-juliat/lutin-306lpc/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/robert-juliat/lutin-306lpc/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
