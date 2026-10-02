# CHAUVET Professional Rogue R3 Beam

- Library state: `researched`
- Identity: model `Rogue R3 Beam`; moving light / beam
- Official source: [https://chauvetprofessional.com/product/rogue-r3-beam/](https://chauvetprofessional.com/product/rogue-r3-beam/) (accessed 2026-10-02)
- Reference envelope: 0.3250 m W × 0.5500 m H × 0.2200 m D
- Control: DMX512, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chauvet-professional/rogue-r3-beam/fixture.json)
- [Blender model](../../../../assets/fixtures/chauvet-professional/rogue-r3-beam/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chauvet-professional/rogue-r3-beam/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chauvet-professional/rogue-r3-beam/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Product specifications state 325 × 220 × 550 mm without named axes; mapped as width × height × depth for a candidate envelope. Confirm mapping against linked CAD before scale modeling.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chauvet-professional/rogue-r3-beam/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
