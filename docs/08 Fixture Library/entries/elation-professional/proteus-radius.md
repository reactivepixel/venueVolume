# Elation Professional Proteus Radius

- Library state: `ready_for_visualization`
- Identity: model `PRD013`; Moving head / beam/hybrid
- Official source: [https://www.elationlighting.com/products/proteus-radius](https://www.elationlighting.com/products/proteus-radius) (accessed 2026-09-30)
- Reference envelope: 0.3950 m W × 0.5160 m H × 0.2700 m D
- Control: DMX, RDM, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/elation-professional/proteus-radius/fixture.json)
- [Blender model](../../../../assets/fixtures/elation-professional/proteus-radius/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/elation-professional/proteus-radius/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/elation-professional/proteus-radius/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer lists length, width and height individually; runtime X/Y/Z uses width/height/length.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 18,516 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/elation-professional/proteus-radius/validation/detail.json) · [Front](../../../../assets/fixtures/elation-professional/proteus-radius/previews/front.png) · [Side](../../../../assets/fixtures/elation-professional/proteus-radius/previews/side.png) · [Rear](../../../../assets/fixtures/elation-professional/proteus-radius/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/elation-professional/proteus-radius/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/elation-professional/proteus-radius/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
