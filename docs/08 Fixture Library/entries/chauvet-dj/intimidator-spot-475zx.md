# CHAUVET DJ Intimidator Spot 475ZX

- Library state: `researched`
- Identity: model `08011956`; moving light / LED spot
- Official source: [https://www.chauvetdj.com/products/intimidator-spot-475zx/](https://www.chauvetdj.com/products/intimidator-spot-475zx/) (accessed 2026-10-02)
- Reference envelope: 0.3630 m W × 0.5310 m H × 0.2500 m D
- Control: DMX512; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chauvet-dj/intimidator-spot-475zx/fixture.json)
- [Blender model](../../../../assets/fixtures/chauvet-dj/intimidator-spot-475zx/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chauvet-dj/intimidator-spot-475zx/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chauvet-dj/intimidator-spot-475zx/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manual lists length 363 mm, width 250 mm, height 531 mm.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chauvet-dj/intimidator-spot-475zx/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
