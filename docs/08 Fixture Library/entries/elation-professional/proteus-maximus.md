# Elation Professional PROTEUS MAXIMUS

- Library state: `researched`
- Identity: model `PROTEUS MAXIMUS`; moving light / profile / spot
- Official source: [https://www.elationlighting.com/products/proteus-maximus](https://www.elationlighting.com/products/proteus-maximus) (accessed 2026-10-02)
- Reference envelope: 0.5910 m W × 0.8280 m H × 0.4580 m D
- Control: DMX, RDM, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/elation-professional/proteus-maximus/fixture.json)
- [Blender model](../../../../assets/fixtures/elation-professional/proteus-maximus/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/elation-professional/proteus-maximus/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/elation-professional/proteus-maximus/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer specifications list length 458 mm × width 591 mm × height 828 mm; mapped to depth × width × height.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/elation-professional/proteus-maximus/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
