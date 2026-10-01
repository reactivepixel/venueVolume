# Elation Professional SIXBAR 500

- Library state: `ready_for_visualization`
- Identity: model `SIX074`; batten / legacy six-pixel RGBAW+UV wash bar
- Official source: [https://www.elationlighting.com/products/sixbar-500](https://www.elationlighting.com/products/sixbar-500) (accessed 2026-09-30)
- Reference envelope: 0.4500 m W × 0.1550 m H × 0.2064 m D
- Control: DMX, RDM, Art-Net, KlingNet; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/elation-professional/sixbar-500/fixture.json)
- [Blender model](../../../../assets/fixtures/elation-professional/sixbar-500/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/elation-professional/sixbar-500/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/elation-professional/sixbar-500/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer defines length, width with included glare shield, and vertical height. Long LED bar axis mapped to width.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `batten` profile with 50 visible meshes and 12,896 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/elation-professional/sixbar-500/validation/detail.json) · [Front](../../../../assets/fixtures/elation-professional/sixbar-500/previews/front.png) · [Side](../../../../assets/fixtures/elation-professional/sixbar-500/previews/side.png) · [Rear](../../../../assets/fixtures/elation-professional/sixbar-500/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/elation-professional/sixbar-500/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/elation-professional/sixbar-500/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
