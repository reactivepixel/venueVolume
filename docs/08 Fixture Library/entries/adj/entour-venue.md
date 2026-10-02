# ADJ Entour Venue

- Library state: `ready_for_visualization`
- Identity: model `ENT610`; equipment / portable water-based faze machine
- Official source: [https://www.adj.com/products/entour-venue](https://www.adj.com/products/entour-venue) (accessed 2026-10-02)
- Reference envelope: 0.3940 m W × 0.2530 m H × 0.4340 m D
- Control: DMX512, manual, timer; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/entour-venue/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/entour-venue/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/entour-venue/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/entour-venue/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- ADJ lists L × W × H = 434 × 394 × 253 mm; external anti-spill fluid reservoir and bracket are not separately dimensioned.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `hazer` profile with 80 visible meshes and 14,400 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/adj/entour-venue/validation/detail.json) · [Front](../../../../assets/fixtures/adj/entour-venue/previews/front.png) · [Side](../../../../assets/fixtures/adj/entour-venue/previews/side.png) · [Rear](../../../../assets/fixtures/adj/entour-venue/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/adj/entour-venue/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/entour-venue/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
