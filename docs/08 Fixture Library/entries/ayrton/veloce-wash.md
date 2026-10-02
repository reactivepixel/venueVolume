# Ayrton Veloce Wash

- Library state: `ready_for_visualization`
- Identity: model `012541`; moving light / IP65 Fresnel wash / profile effects
- Official source: [https://www.ayrton.eu/produit/veloce-wash/](https://www.ayrton.eu/produit/veloce-wash/) (accessed 2026-10-02)
- Reference envelope: 0.4050 m W × 0.7570 m H × 0.3660 m D
- Control: DMX512, RDM, Art-Net, sACN, CRMX wireless DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/ayrton/veloce-wash/fixture.json)
- [Blender model](../../../../assets/fixtures/ayrton/veloce-wash/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/ayrton/veloce-wash/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/ayrton/veloce-wash/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Official product page: 405 x 757 x 366 mm (length x height x depth); manual V1 gives depth 367 mm, so product-page value retained.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 82 visible meshes and 25,552 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/ayrton/veloce-wash/validation/detail.json) · [Front](../../../../assets/fixtures/ayrton/veloce-wash/previews/front.png) · [Side](../../../../assets/fixtures/ayrton/veloce-wash/previews/side.png) · [Rear](../../../../assets/fixtures/ayrton/veloce-wash/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/ayrton/veloce-wash/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/ayrton/veloce-wash/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
