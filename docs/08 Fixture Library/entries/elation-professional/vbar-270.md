# Elation Professional VBAR 270

- Library state: `ready_for_visualization`
- Identity: model `VBAR 270`; batten / legacy compact RGB wash bar
- Official source: [https://www.elationlighting.com/products/vbar-270](https://www.elationlighting.com/products/vbar-270) (accessed 2026-09-30)
- Reference envelope: 0.2500 m W × 0.2120 m H × 0.0930 m D
- Control: DMX-512; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/elation-professional/vbar-270/fixture.json)
- [Blender model](../../../../assets/fixtures/elation-professional/vbar-270/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/elation-professional/vbar-270/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/elation-professional/vbar-270/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer lists length x width x height as 250 x 93 x 212 mm; longest dimension is the bar's lateral span.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `batten` profile with 311 visible meshes and 23,924 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/elation-professional/vbar-270/validation/detail.json) · [Front](../../../../assets/fixtures/elation-professional/vbar-270/previews/front.png) · [Side](../../../../assets/fixtures/elation-professional/vbar-270/previews/side.png) · [Rear](../../../../assets/fixtures/elation-professional/vbar-270/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/elation-professional/vbar-270/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/elation-professional/vbar-270/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
