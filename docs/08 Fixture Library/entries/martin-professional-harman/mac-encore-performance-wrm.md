# Martin Professional (HARMAN) MAC Encore Performance WRM

- Library state: `ready_for_visualization`
- Identity: model `MAC Encore Performance WRM`; moving light / warm-white profile
- Official source: [https://www.martin.com/en-US/products/mac-encore-performance-wrm.html](https://www.martin.com/en-US/products/mac-encore-performance-wrm.html) (accessed 2026-10-02)
- Reference envelope: 0.4800 m W × 0.7400 m H × 0.4520 m D
- Control: DMX512-A, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/martin-professional-harman/mac-encore-performance-wrm/fixture.json)
- [Blender model](../../../../assets/fixtures/martin-professional-harman/mac-encore-performance-wrm/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/martin-professional-harman/mac-encore-performance-wrm/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/martin-professional-harman/mac-encore-performance-wrm/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer physical dimensions: length 452 mm, width 480 mm across yoke, maximum height 740 mm (731 mm head straight up).
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 18,124 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/martin-professional-harman/mac-encore-performance-wrm/validation/detail.json) · [Front](../../../../assets/fixtures/martin-professional-harman/mac-encore-performance-wrm/previews/front.png) · [Side](../../../../assets/fixtures/martin-professional-harman/mac-encore-performance-wrm/previews/side.png) · [Rear](../../../../assets/fixtures/martin-professional-harman/mac-encore-performance-wrm/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/martin-professional-harman/mac-encore-performance-wrm/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/martin-professional-harman/mac-encore-performance-wrm/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
