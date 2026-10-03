# PROLIGHTS Astra Hybrid330

- Library state: `researched`
- Identity: model `ASTRAHYB330`; moving light / hybrid beam / spot / wash
- Official source: [https://prolights.it/en/product/ASTRAHYB330](https://prolights.it/en/product/ASTRAHYB330) (accessed 2026-10-02)
- Reference envelope: 0.4110 m W × 0.6380 m H × 0.2440 m D
- Control: DMX512, RDM, Art-Net, sACN, CRMX, W-DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/prolights/astra-hybrid330/fixture.json)
- [Blender model](../../../../assets/fixtures/prolights/astra-hybrid330/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/prolights/astra-hybrid330/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/prolights/astra-hybrid330/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer product page explicitly lists WxHxD 411 × 638 × 244 mm.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/prolights/astra-hybrid330/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
