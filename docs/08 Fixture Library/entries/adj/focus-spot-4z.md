# ADJ Focus Spot 4Z

- Library state: `ready_for_visualization`
- Identity: model `FOC200`; Moving head / spot
- Official source: [https://www.adj.com/products/focus-spot-4z](https://www.adj.com/products/focus-spot-4z) (accessed 2026-09-30)
- Reference envelope: 0.2786 m W × 0.4574 m H × 0.1815 m D
- Control: DMX512, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/focus-spot-4z/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/focus-spot-4z/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/focus-spot-4z/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/focus-spot-4z/validation/usdz.json)

## Fidelity revision

- Revision 2 replaces the generic proxy with fixture-specific geometry derived from the stored official product image.
- Exact labels, small fasteners, connector geometry, internal mechanisms and photometry remain simplified.

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer specifies L x W x H; runtime X/Y/Z uses W/H/L.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 5 uses a `moving_spot` profile with 85 visible meshes and 18,516 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/adj/focus-spot-4z/validation/detail.json) · [Front](../../../../assets/fixtures/adj/focus-spot-4z/previews/front.png) · [Side](../../../../assets/fixtures/adj/focus-spot-4z/previews/side.png) · [Rear](../../../../assets/fixtures/adj/focus-spot-4z/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/adj/focus-spot-4z/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/focus-spot-4z/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
