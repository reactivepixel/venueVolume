# ETC ColorSource PAR

- Library state: `ready_for_visualization`
- Identity: model `CSPAR`; wash / LED PAR
- Official source: [https://www.etcconnect.com/Products/Lighting-Fixtures/ColorSource/PAR.aspx](https://www.etcconnect.com/Products/Lighting-Fixtures/ColorSource/PAR.aspx) (accessed 2026-09-30)
- Reference envelope: 0.2030 m W × 0.3100 m H × 0.2400 m D
- Control: DMX512, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/etc/colorsource-par/fixture.json)
- [Blender model](../../../../assets/fixtures/etc/colorsource-par/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/etc/colorsource-par/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/etc/colorsource-par/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- ETC technical specification gives assembled fixture dimensions without mounting hardware; 90 W at 120 V.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `par` profile with 62 visible meshes and 22,212 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/etc/colorsource-par/validation/detail.json) · [Front](../../../../assets/fixtures/etc/colorsource-par/previews/front.png) · [Side](../../../../assets/fixtures/etc/colorsource-par/previews/side.png) · [Rear](../../../../assets/fixtures/etc/colorsource-par/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/etc/colorsource-par/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/etc/colorsource-par/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
