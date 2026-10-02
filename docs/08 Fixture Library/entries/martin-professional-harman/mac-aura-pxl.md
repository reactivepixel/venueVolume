# Martin Professional (HARMAN) MAC Aura PXL

- Library state: `ready_for_visualization`
- Identity: model `MAC Aura PXL`; moving light / pixel wash
- Official source: [https://www.martin.com/en-US/products/mac-aura-pxl](https://www.martin.com/en-US/products/mac-aura-pxl) (accessed 2026-10-02)
- Reference envelope: 0.4100 m W × 0.5440 m H × 0.2320 m D
- Control: DMX, RDM, Art-Net, RDM over Art-Net, sACN, Martin P3; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/martin-professional-harman/mac-aura-pxl/fixture.json)
- [Blender model](../../../../assets/fixtures/martin-professional-harman/mac-aura-pxl/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/martin-professional-harman/mac-aura-pxl/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/martin-professional-harman/mac-aura-pxl/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer physical specs: base width 385 mm, maximum height 544 mm, base depth 232 mm; across-yoke width is 410 mm.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 269 visible meshes and 43,192 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/martin-professional-harman/mac-aura-pxl/validation/detail.json) · [Front](../../../../assets/fixtures/martin-professional-harman/mac-aura-pxl/previews/front.png) · [Side](../../../../assets/fixtures/martin-professional-harman/mac-aura-pxl/previews/side.png) · [Rear](../../../../assets/fixtures/martin-professional-harman/mac-aura-pxl/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/martin-professional-harman/mac-aura-pxl/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/martin-professional-harman/mac-aura-pxl/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
