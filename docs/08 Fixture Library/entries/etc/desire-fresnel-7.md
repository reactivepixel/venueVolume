# ETC Desire Fresnel 7

- Library state: `ready_for_visualization`
- Identity: model `DFL7`; wash / LED Fresnel
- Official source: [https://www.etcconnect.com/Products/Entertainment-Fixtures/Desire-Fresnel/Features/](https://www.etcconnect.com/Products/Entertainment-Fixtures/Desire-Fresnel/Features/) (accessed 2026-09-30)
- Reference envelope: 0.3040 m W × 0.4550 m H × 0.3560 m D
- Control: DMX512, RDM, City Theatrical Multiverse wireless DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/etc/desire-fresnel-7/fixture.json)
- [Blender model](../../../../assets/fixtures/etc/desire-fresnel-7/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/etc/desire-fresnel-7/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/etc/desire-fresnel-7/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Corrected from ETC Rev F Physical table: HEIGHT 455 mm × WIDTH 304 mm × DEPTH 356 mm (fully retracted; 505 mm extended). Drawing on p. 11 labels 455 mm vertical and 304 mm crosswise.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `fresnel` profile with 56 visible meshes and 23,496 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/etc/desire-fresnel-7/validation/detail.json) · [Front](../../../../assets/fixtures/etc/desire-fresnel-7/previews/front.png) · [Side](../../../../assets/fixtures/etc/desire-fresnel-7/previews/side.png) · [Rear](../../../../assets/fixtures/etc/desire-fresnel-7/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/etc/desire-fresnel-7/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/etc/desire-fresnel-7/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
