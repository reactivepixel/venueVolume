# CHAUVET DJ Hurricane Haze 2D

- Library state: `researched`
- Identity: model `Hurricane Haze 2D`; equipment / water-based haze machine
- Official source: [https://www.chauvetdj.com/wp-content/uploads/pdf/en/hurricane-haze-2d.pdf](https://www.chauvetdj.com/wp-content/uploads/pdf/en/hurricane-haze-2d.pdf) (accessed 2026-10-02)
- Reference envelope: 0.2850 m W × 0.3500 m H × 0.2670 m D
- Control: DMX512; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chauvet-dj/hurricane-haze-2d/fixture.json)
- [Blender model](../../../../assets/fixtures/chauvet-dj/hurricane-haze-2d/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chauvet-dj/hurricane-haze-2d/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chauvet-dj/hurricane-haze-2d/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer size 285 x 267 x 350 mm; mapped width x depth x height.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chauvet-dj/hurricane-haze-2d/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
