# Le Maitre GForce 3

- Library state: `researched`
- Identity: model `GForce 3`; special effect / continuous-flow smoke machine
- Official source: [https://lemaitreltd.com/products/smoke-fog-haze/smoke-fog-haze-machines/gforce-3/le-maitre-smoke-machine-comparison-breakdown/](https://lemaitreltd.com/products/smoke-fog-haze/smoke-fog-haze-machines/gforce-3/le-maitre-smoke-machine-comparison-breakdown/) (accessed 2026-10-02)
- Reference envelope: 0.2700 m W × 0.4300 m H × 0.5500 m D
- Control: DMX512 (2 channels), manual/timer remote; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/le-maitre/gforce-3/fixture.json)
- [Blender model](../../../../assets/fixtures/le-maitre/gforce-3/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/le-maitre/gforce-3/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/le-maitre/gforce-3/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer gives 270 x 290 x 430 mm, with length 550 mm including bottle carrier; mapped W x H x overall D as 270 x 430 x 550 mm.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/le-maitre/gforce-3/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
