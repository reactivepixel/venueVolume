# Ayrton Bora TC

- Library state: `ready_for_visualization`
- Identity: model `010650`; moving light / high-CRI wash
- Official source: [https://www.ayrton.eu/produit/bora/](https://www.ayrton.eu/produit/bora/) (accessed 2026-10-02)
- Reference envelope: 0.4940 m W × 0.7370 m H × 0.2800 m D
- Control: DMX512, RDM, Art-Net, sACN, CRMX wireless DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/ayrton/bora-tc/fixture.json)
- [Blender model](../../../../assets/fixtures/ayrton/bora-tc/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/ayrton/bora-tc/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/ayrton/bora-tc/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Official product page: 494 x 737 x 280 mm (length x height x depth).
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 73 visible meshes and 18,640 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/ayrton/bora-tc/validation/detail.json) · [Front](../../../../assets/fixtures/ayrton/bora-tc/previews/front.png) · [Side](../../../../assets/fixtures/ayrton/bora-tc/previews/side.png) · [Rear](../../../../assets/fixtures/ayrton/bora-tc/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/ayrton/bora-tc/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/ayrton/bora-tc/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
