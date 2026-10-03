# High End Systems Lonestar

- Library state: `researched`
- Identity: model `Lonestar`; moving light / LED framing profile
- Official source: [https://www.etcconnect.com/lonestar/](https://www.etcconnect.com/lonestar/) (accessed 2026-10-02)
- Reference envelope: 0.3680 m W × 0.6000 m H × 0.2210 m D
- Control: DMX512, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/high-end-systems/lonestar/fixture.json)
- [Blender model](../../../../assets/fixtures/high-end-systems/lonestar/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/high-end-systems/lonestar/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/high-end-systems/lonestar/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer Datasheet Rev H gives W368 × H600 × D221 mm for fixture envelope.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/high-end-systems/lonestar/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
