# GLP JDC Line 500

- Library state: `ready_for_visualization`
- Identity: model `JDC Line 500`; Strobe / blinder / linear hybrid strobe
- Official source: [https://glp.de/de/produkte/entertainment-lighting/strobes/jdc-line-500](https://glp.de/de/produkte/entertainment-lighting/strobes/jdc-line-500) (accessed 2026-09-30)
- Reference envelope: 0.5070 m W × 0.0740 m H × 0.2015 m D
- Control: DMX, RDM, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/glp/jdc-line-500/fixture.json)
- [Blender model](../../../../assets/fixtures/glp/jdc-line-500/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/glp/jdc-line-500/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/glp/jdc-line-500/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer specifies H x W x D.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `strobe` profile with 111 visible meshes and 20,884 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/glp/jdc-line-500/validation/detail.json) · [Front](../../../../assets/fixtures/glp/jdc-line-500/previews/front.png) · [Side](../../../../assets/fixtures/glp/jdc-line-500/previews/side.png) · [Rear](../../../../assets/fixtures/glp/jdc-line-500/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/glp/jdc-line-500/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/glp/jdc-line-500/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
