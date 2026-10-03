# Vari-Lite VL10 BeamWash

- Library state: `researched`
- Identity: model `VL10 BeamWash`; moving light / beam / wash effect
- Official source: [https://www.vari-lite.com/global/products/vl10-beamwash](https://www.vari-lite.com/global/products/vl10-beamwash) (accessed 2026-10-02)
- Reference envelope: 0.7040 m W × 0.5010 m H × 0.3200 m D
- Control: DMX512; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/vari-lite/vl10-beamwash/fixture.json)
- [Blender model](../../../../assets/fixtures/vari-lite/vl10-beamwash/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/vari-lite/vl10-beamwash/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/vari-lite/vl10-beamwash/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer product page gives an unlabelled compact envelope of 704 x 501 x 320 mm; axis mapping to width, height and depth follows its product rendering and is an estimate.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/vari-lite/vl10-beamwash/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
