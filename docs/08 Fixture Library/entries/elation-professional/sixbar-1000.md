# Elation Professional SixBar 1000

- Library state: `ready_for_visualization`
- Identity: model `SIX086`; Batten / LED pixel bar
- Official source: [https://www.elationlighting.com/products/sixbar-1000](https://www.elationlighting.com/products/sixbar-1000) (accessed 2026-09-30)
- Reference envelope: 0.9000 m W × 0.1550 m H × 0.2064 m D
- Control: DMX, Art-Net, Kling-Net, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/elation-professional/sixbar-1000/fixture.json)
- [Blender model](../../../../assets/fixtures/elation-professional/sixbar-1000/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/elation-professional/sixbar-1000/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/elation-professional/sixbar-1000/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer lists bar length, width and height; runtime width follows bar length.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `batten` profile with 62 visible meshes and 18,632 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/elation-professional/sixbar-1000/validation/detail.json) · [Front](../../../../assets/fixtures/elation-professional/sixbar-1000/previews/front.png) · [Side](../../../../assets/fixtures/elation-professional/sixbar-1000/previews/side.png) · [Rear](../../../../assets/fixtures/elation-professional/sixbar-1000/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/elation-professional/sixbar-1000/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/elation-professional/sixbar-1000/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
