# Elation Professional PROTEUS LUCIUS

- Library state: `researched`
- Identity: model `PROTEUS LUCIUS`; moving light / profile / spot
- Official source: [https://www.elationlighting.com/products/proteus-lucius](https://www.elationlighting.com/products/proteus-lucius) (accessed 2026-10-02)
- Reference envelope: 0.3700 m W × 0.6820 m H × 0.4680 m D
- Control: DMX, RDM, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/elation-professional/proteus-lucius/fixture.json)
- [Blender model](../../../../assets/fixtures/elation-professional/proteus-lucius/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/elation-professional/proteus-lucius/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/elation-professional/proteus-lucius/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Current manufacturer specification sheet explicitly labels Length 468 mm, Width 370 mm, Height 682 mm; corroborated by the May 2023 dimensional drawing (base width 370 mm, base length 468 mm, max assembled height 682 mm). Older Proteus series brochure dimensions are superseded and do not match this model's current drawing.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/elation-professional/proteus-lucius/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
