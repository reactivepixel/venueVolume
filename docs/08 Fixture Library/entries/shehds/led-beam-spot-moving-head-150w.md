# SHEHDS LED Beam & Spot Moving Head 150W

- Library state: `researched`
- Identity: model `SHE-NLEDB150W-BPUS`; moving light / LED beam / spot
- Official source: [https://shehds.com/products/new-arrival-led-beam-150w-good-moving-head-lighting](https://shehds.com/products/new-arrival-led-beam-150w-good-moving-head-lighting) (accessed 2026-10-02)
- Reference envelope: 0.2700 m W × 0.4200 m H × 0.1800 m D
- Control: DMX512; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/shehds/led-beam-spot-moving-head-150w/fixture.json)
- [Blender model](../../../../assets/fixtures/shehds/led-beam-spot-moving-head-150w/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/shehds/led-beam-spot-moving-head-150w/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/shehds/led-beam-spot-moving-head-150w/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Official product-size image labels 27 cm head width, 18 cm side depth and 42 cm assembled overall height.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/shehds/led-beam-spot-moving-head-150w/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
