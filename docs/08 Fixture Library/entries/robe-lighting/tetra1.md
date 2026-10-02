# ROBE Lighting Tetra1

- Library state: `researched`
- Identity: model `Tetra1`; linear moving light / single-row multisource batten
- Official source: [https://www.robe.cz/tetra1](https://www.robe.cz/tetra1) (accessed 2026-10-02)
- Reference envelope: 0.5080 m W × 0.2790 m H × 0.1920 m D
- Control: DMX512, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/robe-lighting/tetra1/fixture.json)
- [Blender model](../../../../assets/fixtures/robe-lighting/tetra1/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/robe-lighting/tetra1/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/robe-lighting/tetra1/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Product page dimensions; depth specified with head horizontal.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/robe-lighting/tetra1/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
