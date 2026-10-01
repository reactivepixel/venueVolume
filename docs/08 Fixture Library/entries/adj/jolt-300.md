# ADJ JOLT 300

- Library state: `ready_for_visualization`
- Identity: model `JOL300`; strobe / RGB and cool-white LED strobe/blinder
- Official source: [https://www.adj.com/products/jolt-300](https://www.adj.com/products/jolt-300) (accessed 2026-09-30)
- Reference envelope: 0.3890 m W × 0.2130 m H × 0.1430 m D
- Control: DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/jolt-300/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/jolt-300/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/jolt-300/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/jolt-300/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer states length x width x height as 389 x 143 x 213 mm; long axis represented as width.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `strobe` profile with 111 visible meshes and 20,884 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/adj/jolt-300/validation/detail.json) · [Front](../../../../assets/fixtures/adj/jolt-300/previews/front.png) · [Side](../../../../assets/fixtures/adj/jolt-300/previews/side.png) · [Rear](../../../../assets/fixtures/adj/jolt-300/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/adj/jolt-300/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/jolt-300/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
