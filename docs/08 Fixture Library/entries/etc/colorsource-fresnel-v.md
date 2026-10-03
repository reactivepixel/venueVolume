# ETC ColorSource Fresnel V

- Library state: `ready_for_visualization`
- Identity: model `ColorSource Fresnel V`; Fresnel / LED Fresnel
- Official source: [https://www.etcconnect.com/Products/Entertainment-Fixtures/ColorSource-Fresnel-V/Documentation.aspx](https://www.etcconnect.com/Products/Entertainment-Fixtures/ColorSource-Fresnel-V/Documentation.aspx) (accessed 2026-09-30)
- Reference envelope: 0.3210 m W × 0.3390 m H × 0.3110 m D
- Control: DMX, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/etc/colorsource-fresnel-v/fixture.json)
- [Blender model](../../../../assets/fixtures/etc/colorsource-fresnel-v/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/etc/colorsource-fresnel-v/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/etc/colorsource-fresnel-v/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer specifies H x W x D.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `fresnel` profile with 56 visible meshes and 23,496 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/etc/colorsource-fresnel-v/validation/detail.json) · [Front](../../../../assets/fixtures/etc/colorsource-fresnel-v/previews/front.png) · [Side](../../../../assets/fixtures/etc/colorsource-fresnel-v/previews/side.png) · [Rear](../../../../assets/fixtures/etc/colorsource-fresnel-v/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/etc/colorsource-fresnel-v/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/etc/colorsource-fresnel-v/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
