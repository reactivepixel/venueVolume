# GLP MAD MAXX

- Library state: `ready_for_visualization`
- Identity: model `7992`; moving light / fat beam / multisource effect
- Official source: [https://glp.de/en/products/entertainment-lighting/moving-lights/mad-maxx-en](https://glp.de/en/products/entertainment-lighting/moving-lights/mad-maxx-en) (accessed 2026-10-02)
- Reference envelope: 1.0430 m W × 1.0570 m H × 0.7890 m D
- Control: DMX512-A, RDM, CRMX DMX/RDM, Art-Net, sACN, GLP iQ.Mesh; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/glp/mad-maxx/fixture.json)
- [Blender model](../../../../assets/fixtures/glp/mad-maxx/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/glp/mad-maxx/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/glp/mad-maxx/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- GLP product page lists width 1043 mm, height 1057 mm, depth 789 mm; with head straight up the alternate envelope is 1248 mm high and 528 mm deep.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 128 visible meshes and 38,244 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/glp/mad-maxx/validation/detail.json) · [Front](../../../../assets/fixtures/glp/mad-maxx/previews/front.png) · [Side](../../../../assets/fixtures/glp/mad-maxx/previews/side.png) · [Rear](../../../../assets/fixtures/glp/mad-maxx/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/glp/mad-maxx/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/glp/mad-maxx/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
