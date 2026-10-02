# Ayrton Khamsin TC

- Library state: `researched`
- Identity: model `011650`; moving light / high-CRI profile
- Official source: [https://www.ayrton.eu/produit/khamsin/](https://www.ayrton.eu/produit/khamsin/) (accessed 2026-10-02)
- Reference envelope: 0.4940 m W × 0.7780 m H × 0.2800 m D
- Control: DMX512, RDM, Art-Net, sACN, CRMX wireless DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/ayrton/khamsin-tc/fixture.json)
- [Blender model](../../../../assets/fixtures/ayrton/khamsin-tc/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/ayrton/khamsin-tc/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/ayrton/khamsin-tc/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Current Ayrton product page: 494 x 778 x 280 mm. An older manual gives a different height; current page value retained.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/ayrton/khamsin-tc/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
