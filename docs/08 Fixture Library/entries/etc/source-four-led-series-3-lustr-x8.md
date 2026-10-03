# ETC Source Four LED Series 3 Lustr X8

- Library state: `researched`
- Identity: model `S4LEDS3LS-0`; Profile / ellipsoidal LED
- Official source: [https://www.etcconnect.com/Products/Entertainment-Fixtures/Source-Four-LED-Series-3/Documentation.aspx](https://www.etcconnect.com/Products/Entertainment-Fixtures/Source-Four-LED-Series-3/Documentation.aspx) (accessed 2026-09-30)
- Reference envelope: 0.3400 m W × 0.3400 m H × 0.7210 m D
- Control: DMX512, RDM, wireless DMX/RDM (Multiverse); exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/etc/source-four-led-series-3-lustr-x8/fixture.json)
- [Blender model](../../../../assets/fixtures/etc/source-four-led-series-3-lustr-x8/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/etc/source-four-led-series-3-lustr-x8/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/etc/source-four-led-series-3-lustr-x8/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Maximum lens-tube envelope is documented; long axis is assigned to runtime depth.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `profile` profile with 47 visible meshes and 16,908 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/etc/source-four-led-series-3-lustr-x8/validation/detail.json) · [Front](../../../../assets/fixtures/etc/source-four-led-series-3-lustr-x8/previews/front.png) · [Side](../../../../assets/fixtures/etc/source-four-led-series-3-lustr-x8/previews/side.png) · [Rear](../../../../assets/fixtures/etc/source-four-led-series-3-lustr-x8/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/etc/source-four-led-series-3-lustr-x8/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/etc/source-four-led-series-3-lustr-x8/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
