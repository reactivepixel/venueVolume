# GLP JDC1

- Library state: `ready_for_visualization`
- Identity: model `JDC1`; Strobe / blinder / hybrid strobe
- Official source: [https://glp.de/en/products/entertainment-lighting/strobes/jdc1-en?ic=1](https://glp.de/en/products/entertainment-lighting/strobes/jdc1-en?ic=1) (accessed 2026-09-30)
- Reference envelope: 0.3900 m W × 0.2510 m H × 0.1500 m D
- Control: DMX512-A, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/glp/jdc1/fixture.json)
- [Blender model](../../../../assets/fixtures/glp/jdc1/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/glp/jdc1/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/glp/jdc1/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer specifies H x W x D.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 4 uses a `strobe` profile with 112 visible meshes and 21,072 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/glp/jdc1/validation/detail.json) · [Front](../../../../assets/fixtures/glp/jdc1/previews/front.png) · [Side](../../../../assets/fixtures/glp/jdc1/previews/side.png) · [Rear](../../../../assets/fixtures/glp/jdc1/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/glp/jdc1/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/glp/jdc1/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
