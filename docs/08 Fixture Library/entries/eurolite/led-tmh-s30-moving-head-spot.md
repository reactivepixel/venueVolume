# Eurolite LED TMH-S30 Moving-Head Spot

- Library state: `researched`
- Identity: model `51786070`; moving light / compact LED spot
- Official source: [https://www.steinigke.de/mpn51786070-eurolite-led-tmh-s30-moving-head-spot.html](https://www.steinigke.de/mpn51786070-eurolite-led-tmh-s30-moving-head-spot.html) (accessed 2026-10-02)
- Reference envelope: 0.1700 m W × 0.2400 m H × 0.1500 m D
- Control: DMX512; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/eurolite/led-tmh-s30-moving-head-spot/fixture.json)
- [Blender model](../../../../assets/fixtures/eurolite/led-tmh-s30-moving-head-spot/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/eurolite/led-tmh-s30-moving-head-spot/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/eurolite/led-tmh-s30-moving-head-spot/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Steinigke product specification explicitly gives width 17.0 cm, height 24.0 cm, depth 15.0 cm.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/eurolite/led-tmh-s30-moving-head-spot/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
