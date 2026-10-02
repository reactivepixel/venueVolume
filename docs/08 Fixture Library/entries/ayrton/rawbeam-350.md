# Ayrton Rawbeam 350

- Library state: `ready_for_visualization`
- Identity: model `014350`; moving light / IP65 laser-source beam / spot
- Official source: [https://www.ayrton.eu/produit/rawbeam-350/](https://www.ayrton.eu/produit/rawbeam-350/) (accessed 2026-10-02)
- Reference envelope: 0.3390 m W × 0.5920 m H × 0.2970 m D
- Control: DMX512, RDM, Art-Net, sACN, CRMX wireless DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/ayrton/rawbeam-350/fixture.json)
- [Blender model](../../../../assets/fixtures/ayrton/rawbeam-350/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/ayrton/rawbeam-350/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/ayrton/rawbeam-350/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Official product page: 339 x 592 x 297 mm (length x height x depth).
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 17,996 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/ayrton/rawbeam-350/validation/detail.json) · [Front](../../../../assets/fixtures/ayrton/rawbeam-350/previews/front.png) · [Side](../../../../assets/fixtures/ayrton/rawbeam-350/previews/side.png) · [Rear](../../../../assets/fixtures/ayrton/rawbeam-350/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/ayrton/rawbeam-350/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/ayrton/rawbeam-350/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
