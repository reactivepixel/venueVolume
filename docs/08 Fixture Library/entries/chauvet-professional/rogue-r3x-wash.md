# CHAUVET Professional Rogue R3X Wash

- Library state: `researched`
- Identity: model `Rogue R3X Wash`; moving light / wash
- Official source: [https://chauvetprofessional.com/product/rogue-r3x-wash/](https://chauvetprofessional.com/product/rogue-r3x-wash/) (accessed 2026-10-02)
- Reference envelope: 0.3940 m W × 0.4700 m H × 0.2980 m D
- Control: DMX512, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chauvet-professional/rogue-r3x-wash/fixture.json)
- [Blender model](../../../../assets/fixtures/chauvet-professional/rogue-r3x-wash/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chauvet-professional/rogue-r3x-wash/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chauvet-professional/rogue-r3x-wash/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- User Manual Rev. 8, Product Dimensions drawing (p. 5): 394 mm front width × 470 mm maximum height × 298 mm depth, assembled neutral pose.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chauvet-professional/rogue-r3x-wash/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
