# Claypaky B-Eye 7

- Library state: `researched`
- Identity: model `CL3046`; moving light / IP66 RGBL wash
- Official source: [https://www.claypaky.it/products/b-eye-7/](https://www.claypaky.it/products/b-eye-7/) (accessed 2026-10-02)
- Reference envelope: 0.3500 m W × 0.4609 m H × 0.2048 m D
- Control: DMX, Art-Net, RDM, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/claypaky/b-eye-7/fixture.json)
- [Blender model](../../../../assets/fixtures/claypaky/b-eye-7/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/claypaky/b-eye-7/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/claypaky/b-eye-7/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer states 350 x 204.8 mm base and 460.9 mm vertical-head height; assignment of base axes to width/depth follows product views and is estimated.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/claypaky/b-eye-7/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
