# ROE Visual Black Pearl BP2V2

- Library state: `ready_for_visualization`
- Identity: model `BP2V2`; indoor_led_display_panel / 2.84 mm pixel-pitch broadcast/virtual-production LED panel
- Official source: [https://www.roevisual.com/en/products/black-pearl-2v2](https://www.roevisual.com/en/products/black-pearl-2v2) (accessed 2026-09-30)
- Reference envelope: 0.5000 m W × 0.5000 m H × 0.0900 m D
- Control: Video content path through supported LED processing platform to panel data connection; panel power path is separate. Not DMX-controlled lighting.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/roe-visual/black-pearl-bp2v2/fixture.json)
- [Blender model](../../../../assets/fixtures/roe-visual/black-pearl-bp2v2/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/roe-visual/black-pearl-bp2v2/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/roe-visual/black-pearl-bp2v2/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- 500 x 500 x 90 mm per panel
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `led_panel` profile with 9 visible meshes and 1,692 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/roe-visual/black-pearl-bp2v2/validation/detail.json) · [Front](../../../../assets/fixtures/roe-visual/black-pearl-bp2v2/previews/front.png) · [Side](../../../../assets/fixtures/roe-visual/black-pearl-bp2v2/previews/side.png) · [Rear](../../../../assets/fixtures/roe-visual/black-pearl-bp2v2/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/roe-visual/black-pearl-bp2v2/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/roe-visual/black-pearl-bp2v2/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
