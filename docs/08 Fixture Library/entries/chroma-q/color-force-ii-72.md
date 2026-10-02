# Chroma-Q Color Force II 72

- Library state: `researched`
- Identity: model `CHCF272RGBA`; LED wash / cyc / wash batten
- Official source: [https://chroma-q.com/products/color-force-ii-72](https://chroma-q.com/products/color-force-ii-72) (accessed 2026-10-02)
- Reference envelope: 1.7590 m W × 0.1910 m H × 0.1650 m D
- Control: DMX512-A; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chroma-q/color-force-ii-72/fixture.json)
- [Blender model](../../../../assets/fixtures/chroma-q/color-force-ii-72/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chroma-q/color-force-ii-72/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chroma-q/color-force-ii-72/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer mechanical specifications; optical-forward neutral pose and detail proportions are image-informed estimates.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chroma-q/color-force-ii-72/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
