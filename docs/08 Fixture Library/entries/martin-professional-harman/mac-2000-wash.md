# Martin Professional (HARMAN) MAC 2000 Wash

- Library state: `researched`
- Identity: model `MAC 2000 Wash`; moving light / wash
- Official source: [https://www.martin.com/en-US/products/mac-2000-wash](https://www.martin.com/en-US/products/mac-2000-wash) (accessed 2026-10-02)
- Reference envelope: 0.4900 m W × 0.7500 m H × 0.4080 m D
- Control: USITT DMX512/1990; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/martin-professional-harman/mac-2000-wash/fixture.json)
- [Blender model](../../../../assets/fixtures/martin-professional-harman/mac-2000-wash/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/martin-professional-harman/mac-2000-wash/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/martin-professional-harman/mac-2000-wash/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Martin physical specification: length 408 mm, width 490 mm, height 750 mm head straight up.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/martin-professional-harman/mac-2000-wash/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
