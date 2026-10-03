# High End Systems Lonestar Prime

- Library state: `researched`
- Identity: model `Lonestar Prime`; moving light / profile / framing spot, IP54
- Official source: [https://www.etcconnect.com/Lonestar-Prime/](https://www.etcconnect.com/Lonestar-Prime/) (accessed 2026-10-02)
- Reference envelope: 0.3500 m W × 0.5840 m H × 0.2300 m D
- Control: DMX512; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/high-end-systems/lonestar-prime/fixture.json)
- [Blender model](../../../../assets/fixtures/high-end-systems/lonestar-prime/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/high-end-systems/lonestar-prime/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/high-end-systems/lonestar-prime/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer datasheet explicitly lists height 584 mm, width 350 mm and depth 230 mm; fixture excluding mounting hardware.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/high-end-systems/lonestar-prime/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
