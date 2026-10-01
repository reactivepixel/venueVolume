# ADJ Jolt Bar FX2

- Library state: `ready_for_visualization`
- Identity: model `JOL286`; batten / RGB and white LED strobe/blinder bar
- Official source: [https://www.adj.com/products/jolt-bar-fx2](https://www.adj.com/products/jolt-bar-fx2) (accessed 2026-09-30)
- Reference envelope: 1.0000 m W × 0.1010 m H × 0.1035 m D
- Control: DMX, RDM, Aria X2; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/jolt-bar-fx2/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/jolt-bar-fx2/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/jolt-bar-fx2/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/jolt-bar-fx2/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer states 1000 x 103.5 x 101 mm as length x width x height; longitudinal bar axis is width in this record.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `strobe` profile with 123 visible meshes and 23,140 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/adj/jolt-bar-fx2/validation/detail.json) · [Front](../../../../assets/fixtures/adj/jolt-bar-fx2/previews/front.png) · [Side](../../../../assets/fixtures/adj/jolt-bar-fx2/previews/side.png) · [Rear](../../../../assets/fixtures/adj/jolt-bar-fx2/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/adj/jolt-bar-fx2/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/jolt-bar-fx2/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
