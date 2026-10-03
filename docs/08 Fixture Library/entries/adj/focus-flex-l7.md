# ADJ Focus Flex L7

- Library state: `researched`
- Identity: model `FOC734`; moving light / seven-pixel RGBL wash
- Official source: [https://www.adj.com/products/focus-flex-l7](https://www.adj.com/products/focus-flex-l7) (accessed 2026-10-02)
- Reference envelope: 0.2500 m W × 0.3490 m H × 0.1790 m D
- Control: DMX512, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/focus-flex-l7/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/focus-flex-l7/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/focus-flex-l7/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/focus-flex-l7/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- ADJ labels L x W x H = 178.8 x 250.0 x 349.2 mm; 250 mm cross-head span mapped to width, 349.2 mm upright height, 178.8 mm front-back depth.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/focus-flex-l7/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
