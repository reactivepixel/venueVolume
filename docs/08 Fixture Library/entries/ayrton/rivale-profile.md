# Ayrton Rivale Profile

- Library state: `ready_for_visualization`
- Identity: model `Rivale Profile`; moving light / IP65 profile
- Official source: [https://www.ayrton.eu/produit/rivale-profile/](https://www.ayrton.eu/produit/rivale-profile/) (accessed 2026-10-02)
- Reference envelope: 0.3600 m W × 0.6760 m H × 0.3160 m D
- Control: DMX 512, DMX-RDM, ArtNet, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/ayrton/rivale-profile/fixture.json)
- [Blender model](../../../../assets/fixtures/ayrton/rivale-profile/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/ayrton/rivale-profile/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/ayrton/rivale-profile/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer technical specification lists product dimensions 360 x 676 x 316 mm (l x h x d); flight-case dimensions excluded.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 17,996 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/ayrton/rivale-profile/validation/detail.json) · [Front](../../../../assets/fixtures/ayrton/rivale-profile/previews/front.png) · [Side](../../../../assets/fixtures/ayrton/rivale-profile/previews/side.png) · [Rear](../../../../assets/fixtures/ayrton/rivale-profile/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/ayrton/rivale-profile/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/ayrton/rivale-profile/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
