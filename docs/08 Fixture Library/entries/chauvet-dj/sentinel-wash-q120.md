# CHAUVET DJ Sentinel Wash Q120

- Library state: `researched`
- Identity: model `Sentinel Wash Q120`; moving light / RGBW Fresnel wash
- Official source: [https://www.chauvetdj.com/products/sentinel-wash-q120/](https://www.chauvetdj.com/products/sentinel-wash-q120/) (accessed 2026-10-02)
- Reference envelope: 0.2190 m W × 0.2960 m H × 0.1430 m D
- Control: DMX512; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chauvet-dj/sentinel-wash-q120/fixture.json)
- [Blender model](../../../../assets/fixtures/chauvet-dj/sentinel-wash-q120/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chauvet-dj/sentinel-wash-q120/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chauvet-dj/sentinel-wash-q120/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer size 219 x 143 x 296 mm; mapped width x depth x height.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chauvet-dj/sentinel-wash-q120/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
