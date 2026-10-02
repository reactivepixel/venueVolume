# Ayrton Cobra²

- Library state: `researched`
- Identity: model `014175`; moving light / IP65 phosphor-laser beam
- Official source: [https://www.ayrton.eu/produit/cobra2/](https://www.ayrton.eu/produit/cobra2/) (accessed 2026-10-02)
- Reference envelope: 0.3600 m W × 0.6740 m H × 0.3190 m D
- Control: DMX512, RDM, Art-Net, sACN, CRMX wireless DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/ayrton/cobra/fixture.json)
- [Blender model](../../../../assets/fixtures/ayrton/cobra/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/ayrton/cobra/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/ayrton/cobra/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Ayrton product page dimensions: 360 x 674 x 319 mm (length x height x depth).
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/ayrton/cobra/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
