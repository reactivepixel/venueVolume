# ADJ Jolt Bar FX

- Library state: `ready_for_visualization`
- Identity: model `JOLT-BAR-FX`; Batten / LED strobe/blinder bar
- Official source: [https://www.adj.com/products/jolt-bar-fx](https://www.adj.com/products/jolt-bar-fx) (accessed 2026-09-30)
- Reference envelope: 1.0000 m W × 0.1230 m H × 0.1070 m D
- Control: DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/jolt-bar-fx/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/jolt-bar-fx/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/jolt-bar-fx/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/jolt-bar-fx/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer specifies bar L x W x H; runtime width follows bar length.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `strobe` profile with 99 visible meshes and 18,628 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/adj/jolt-bar-fx/validation/detail.json) · [Front](../../../../assets/fixtures/adj/jolt-bar-fx/previews/front.png) · [Side](../../../../assets/fixtures/adj/jolt-bar-fx/previews/side.png) · [Rear](../../../../assets/fixtures/adj/jolt-bar-fx/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/adj/jolt-bar-fx/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/jolt-bar-fx/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
