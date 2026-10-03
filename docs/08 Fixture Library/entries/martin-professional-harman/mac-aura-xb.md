# Martin Professional (HARMAN) MAC Aura XB

- Library state: `ready_for_visualization`
- Identity: model `MAC Aura XB`; moving light / high-output wash / Aura pixel effect
- Official source: [https://www.martin.com/en-US/products/mac-aura-xb](https://www.martin.com/en-US/products/mac-aura-xb) (accessed 2026-10-02)
- Reference envelope: 0.2220 m W × 0.3900 m H × 0.1380 m D
- Control: DMX, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/martin-professional-harman/mac-aura-xb/fixture.json)
- [Blender model](../../../../assets/fixtures/martin-professional-harman/mac-aura-xb/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/martin-professional-harman/mac-aura-xb/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/martin-professional-harman/mac-aura-xb/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer physical specs: base width 222 mm, maximum height 390 mm, base depth 138 mm; across-yoke width is 302 mm.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 164 visible meshes and 39,700 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/martin-professional-harman/mac-aura-xb/validation/detail.json) · [Front](../../../../assets/fixtures/martin-professional-harman/mac-aura-xb/previews/front.png) · [Side](../../../../assets/fixtures/martin-professional-harman/mac-aura-xb/previews/side.png) · [Rear](../../../../assets/fixtures/martin-professional-harman/mac-aura-xb/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/martin-professional-harman/mac-aura-xb/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/martin-professional-harman/mac-aura-xb/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
