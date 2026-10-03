# JB-Lighting Sparx 30

- Library state: `researched`
- Identity: model `Sparx 30`; moving light / pixel wash
- Official source: [https://www.jb-lighting.de/en/Sparx30](https://www.jb-lighting.de/en/Sparx30) (accessed 2026-10-02)
- Reference envelope: 0.5300 m W × 0.6280 m H × 0.3080 m D
- Control: DMX512, RDM, Art-Net, sACN, Kling-Net, CRMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/jb-lighting/sparx-30/fixture.json)
- [Blender model](../../../../assets/fixtures/jb-lighting/sparx-30/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/jb-lighting/sparx-30/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/jb-lighting/sparx-30/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer mechanical specifications; optical-forward neutral pose and detail proportions are image-informed estimates.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/jb-lighting/sparx-30/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
