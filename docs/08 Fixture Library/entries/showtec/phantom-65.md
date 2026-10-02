# Showtec Phantom 65

- Library state: `researched`
- Identity: model `40070`; moving light / LED spot
- Official source: [https://www.highlite.com/media/attachments/MANUAL/40070_MANUAL_GB_V1.pdf](https://www.highlite.com/media/attachments/MANUAL/40070_MANUAL_GB_V1.pdf) (accessed 2026-10-02)
- Reference envelope: 0.2300 m W × 0.3650 m H × 0.2000 m D
- Control: DMX512; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/showtec/phantom-65/fixture.json)
- [Blender model](../../../../assets/fixtures/showtec/phantom-65/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/showtec/phantom-65/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/showtec/phantom-65/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manual lists 230 x 200 x 365 mm, L x W x H.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/showtec/phantom-65/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
