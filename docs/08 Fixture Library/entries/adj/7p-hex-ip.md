# ADJ 7P HEX IP

- Library state: `ready_for_visualization`
- Identity: model `HEX700`; PAR / IP65 LED wash
- Official source: [https://www.adj.com/products/7p-hex-ip](https://www.adj.com/products/7p-hex-ip) (accessed 2026-09-30)
- Reference envelope: 0.2560 m W × 0.2348 m H × 0.1704 m D
- Control: DMX, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/7p-hex-ip/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/7p-hex-ip/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/7p-hex-ip/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/7p-hex-ip/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer specifies L x W x H; runtime X/Y/Z uses W/H/L.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `par` profile with 64 visible meshes and 22,588 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/adj/7p-hex-ip/validation/detail.json) · [Front](../../../../assets/fixtures/adj/7p-hex-ip/previews/front.png) · [Side](../../../../assets/fixtures/adj/7p-hex-ip/previews/side.png) · [Rear](../../../../assets/fixtures/adj/7p-hex-ip/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/adj/7p-hex-ip/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/7p-hex-ip/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
