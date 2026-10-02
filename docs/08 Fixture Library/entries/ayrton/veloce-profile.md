# Ayrton Veloce Profile

- Library state: `researched`
- Identity: model `012521`; moving light / IP65 profile
- Official source: [https://www.ayrton.eu/produit/veloce-profile/](https://www.ayrton.eu/produit/veloce-profile/) (accessed 2026-10-02)
- Reference envelope: 0.4040 m W × 0.7570 m H × 0.3660 m D
- Control: DMX512, RDM, Art-Net, sACN, CRMX wireless DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/ayrton/veloce-profile/fixture.json)
- [Blender model](../../../../assets/fixtures/ayrton/veloce-profile/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/ayrton/veloce-profile/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/ayrton/veloce-profile/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Product page lists 404 x 757 x 366 mm; 2024 sheet rounds length to 405 mm. Page value retained.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/ayrton/veloce-profile/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
