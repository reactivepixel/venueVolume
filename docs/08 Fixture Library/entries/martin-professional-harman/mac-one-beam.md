# Martin Professional (HARMAN) MAC One Beam

- Library state: `ready_for_visualization`
- Identity: model `MAC One Beam`; moving light / beam / effect
- Official source: [https://www.martin.com/en-US/products/mac-one-beam](https://www.martin.com/en-US/products/mac-one-beam) (accessed 2026-10-02)
- Reference envelope: 0.2540 m W × 0.3500 m H × 0.2330 m D
- Control: DMX, Art-Net, sACN, Martin P3; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/martin-professional-harman/mac-one-beam/fixture.json)
- [Blender model](../../../../assets/fixtures/martin-professional-harman/mac-one-beam/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/martin-professional-harman/mac-one-beam/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/martin-professional-harman/mac-one-beam/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer physical specs: base width 254 mm, maximum height 350 mm, head depth 233 mm. Across-yoke width is 226 mm; dimensions intentionally use base width and maximum vertical envelope.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 133 visible meshes and 27,604 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/martin-professional-harman/mac-one-beam/validation/detail.json) · [Front](../../../../assets/fixtures/martin-professional-harman/mac-one-beam/previews/front.png) · [Side](../../../../assets/fixtures/martin-professional-harman/mac-one-beam/previews/side.png) · [Rear](../../../../assets/fixtures/martin-professional-harman/mac-one-beam/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/martin-professional-harman/mac-one-beam/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/martin-professional-harman/mac-one-beam/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
