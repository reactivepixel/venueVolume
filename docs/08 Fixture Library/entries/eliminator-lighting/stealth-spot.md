# Eliminator Lighting Stealth Spot

- Library state: `researched`
- Identity: model `Stealth Spot`; moving light / LED spot
- Official source: [https://www.eliminatorlighting.com/products/stealth-spot](https://www.eliminatorlighting.com/products/stealth-spot) (accessed 2026-10-02)
- Reference envelope: 0.1700 m W × 0.3550 m H × 0.2390 m D
- Control: DMX512; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/eliminator-lighting/stealth-spot/fixture.json)
- [Blender model](../../../../assets/fixtures/eliminator-lighting/stealth-spot/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/eliminator-lighting/stealth-spot/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/eliminator-lighting/stealth-spot/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer lists 239 x 170 x 355 mm, L x W x H.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/eliminator-lighting/stealth-spot/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
