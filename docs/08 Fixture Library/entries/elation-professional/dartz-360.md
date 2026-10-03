# Elation Professional DARTZ 360

- Library state: `ready_for_visualization`
- Identity: model `DAR880`; Moving head / beam
- Official source: [https://www.elationlighting.com/products/dartz-360](https://www.elationlighting.com/products/dartz-360) (accessed 2026-09-30)
- Reference envelope: 0.1960 m W × 0.4547 m H × 0.2842 m D
- Control: DMX, RDM, Kling-Net, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/elation-professional/dartz-360/fixture.json)
- [Blender model](../../../../assets/fixtures/elation-professional/dartz-360/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/elation-professional/dartz-360/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/elation-professional/dartz-360/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer lists length, width and height individually; runtime X/Y/Z uses width/height/length.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 18,580 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/elation-professional/dartz-360/validation/detail.json) · [Front](../../../../assets/fixtures/elation-professional/dartz-360/previews/front.png) · [Side](../../../../assets/fixtures/elation-professional/dartz-360/previews/side.png) · [Rear](../../../../assets/fixtures/elation-professional/dartz-360/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/elation-professional/dartz-360/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/elation-professional/dartz-360/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
