# ADJ X-Move Laser

- Library state: `researched`
- Identity: model `X-Move Laser`; special effect / green laser moving head
- Official source: [https://www.adj.com/products/x-move-laser](https://www.adj.com/products/x-move-laser) (accessed 2026-10-02)
- Reference envelope: 0.1900 m W × 0.2850 m H × 0.2050 m D
- Control: DMX512 (6 channels), sound active, primary/secondary; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/x-move-laser/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/x-move-laser/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/x-move-laser/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/x-move-laser/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer L x W x H 205 x 190 x 285 mm; mapped to width 190, height 285, depth 205 mm.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 18,124 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/adj/x-move-laser/validation/detail.json) · [Front](../../../../assets/fixtures/adj/x-move-laser/previews/front.png) · [Side](../../../../assets/fixtures/adj/x-move-laser/previews/side.png) · [Rear](../../../../assets/fixtures/adj/x-move-laser/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/adj/x-move-laser/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/x-move-laser/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
