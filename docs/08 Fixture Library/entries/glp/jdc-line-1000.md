# GLP JDC Line 1000

- Library state: `ready_for_visualization`
- Identity: model `7875`; linear LED effect / strobe / pixel batten
- Official source: [https://www1.glp.de/en/products/entertainment-lighting/strobes/jdc-line-1000-en](https://www1.glp.de/en/products/entertainment-lighting/strobes/jdc-line-1000-en) (accessed 2026-09-30)
- Reference envelope: 1.0000 m W × 0.0740 m H × 0.2015 m D
- Control: DMX512-A, RDM, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/glp/jdc-line-1000/fixture.json)
- [Blender model](../../../../assets/fixtures/glp/jdc-line-1000/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/glp/jdc-line-1000/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/glp/jdc-line-1000/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- GLP JDC Line 1000 product page; width 1000 mm, height 74 mm, depth 201.5 mm. Body without optional rigging or alignment brackets.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `batten` profile with 39 visible meshes and 7,348 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/glp/jdc-line-1000/validation/detail.json) · [Front](../../../../assets/fixtures/glp/jdc-line-1000/previews/front.png) · [Side](../../../../assets/fixtures/glp/jdc-line-1000/previews/side.png) · [Rear](../../../../assets/fixtures/glp/jdc-line-1000/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/glp/jdc-line-1000/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/glp/jdc-line-1000/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
