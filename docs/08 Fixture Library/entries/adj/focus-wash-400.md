# ADJ Focus Wash 400

- Library state: `researched`
- Identity: model `FOC615`; moving light / RGBACL LED Fresnel wash
- Official source: [https://www.adj.com/products/focus-wash-400](https://www.adj.com/products/focus-wash-400) (accessed 2026-10-02)
- Reference envelope: 0.2133 m W × 0.4981 m H × 0.2784 m D
- Control: DMX512, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/focus-wash-400/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/focus-wash-400/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/focus-wash-400/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/focus-wash-400/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- ADJ lists width 213.33 mm, vertical height 498.1 mm without snoot, and length 278.43 mm.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/focus-wash-400/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
