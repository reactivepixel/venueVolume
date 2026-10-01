# ADJ LED Bar

- Library state: `ready_for_visualization`
- Identity: model `LED BAR`; Batten / LED wash bar
- Official source: [https://www.adj.com/products/led-bar](https://www.adj.com/products/led-bar) (accessed 2026-09-30)
- Reference envelope: 0.5000 m W × 0.1320 m H × 0.0900 m D
- Control: DMX-512; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/led-bar/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/led-bar/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/led-bar/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/led-bar/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer specifies bar L x W x H; runtime width follows bar length.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `batten` profile with 122 visible meshes and 14,328 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/adj/led-bar/validation/detail.json) · [Front](../../../../assets/fixtures/adj/led-bar/previews/front.png) · [Side](../../../../assets/fixtures/adj/led-bar/previews/side.png) · [Rear](../../../../assets/fixtures/adj/led-bar/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/adj/led-bar/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/led-bar/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
