# ETC ColorSource 20

- Library state: `ready_for_visualization`
- Identity: model `CS20`; lighting_console / 20-fader theatrical lighting console
- Official source: [https://www.etcconnect.com/products/consoles/colorsource/features.aspx](https://www.etcconnect.com/products/consoles/colorsource/features.aspx) (accessed 2026-09-30)
- Reference envelope: 0.4650 m W × 0.0600 m H × 0.2790 m D
- Control: Console outputs control over one 5-pin DMX port to DMX fixtures/nodes. Base ColorSource 20 feature table does not list sACN/Art-Net; do not conflate with the AV variant.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/etc/colorsource-20/fixture.json)
- [Blender model](../../../../assets/fixtures/etc/colorsource-20/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/etc/colorsource-20/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/etc/colorsource-20/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- 465 W x 279 D x 60 H mm, ColorSource Console Spec Sheet rev G; values typical
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `console` profile with 81 visible meshes and 14,844 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/etc/colorsource-20/validation/detail.json) · [Front](../../../../assets/fixtures/etc/colorsource-20/previews/front.png) · [Side](../../../../assets/fixtures/etc/colorsource-20/previews/side.png) · [Rear](../../../../assets/fixtures/etc/colorsource-20/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/etc/colorsource-20/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/etc/colorsource-20/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
