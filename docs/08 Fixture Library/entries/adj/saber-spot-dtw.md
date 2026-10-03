# ADJ Saber Spot DTW

- Library state: `researched`
- Identity: model `SAB990`; LED spotlight / warm-white dim-to-warm pinspot
- Official source: [https://www.adj.com/products/saber-spot-dtw](https://www.adj.com/products/saber-spot-dtw) (accessed 2026-10-02)
- Reference envelope: 0.1700 m W × 0.0870 m H × 0.0880 m D
- Control: DMX512, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/saber-spot-dtw/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/saber-spot-dtw/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/saber-spot-dtw/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/saber-spot-dtw/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- ADJ labels dimensions L x W x H = 88 x 170 x 87 mm; elongated scissor-bracket dimension is treated as width and lens-axis length as depth.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/saber-spot-dtw/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
