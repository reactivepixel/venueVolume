# ETC fos/4 Fresnel

- Library state: `researched`
- Identity: model `fos/4 Fresnel`; Fresnel / LED Fresnel
- Official source: [https://www.etcconnect.com/Products/Entertainment-Fixtures/fos/4-Fresnel/Documentation.aspx](https://www.etcconnect.com/Products/Entertainment-Fixtures/fos/4-Fresnel/Documentation.aspx) (accessed 2026-09-30)
- Reference envelope: 0.3130 m W × 0.4350 m H × 0.5050 m D
- Control: DMX, RDM, wireless DMX/RDM (Multiverse); exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/etc/fos-4-fresnel/fixture.json)
- [Blender model](../../../../assets/fixtures/etc/fos-4-fresnel/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/etc/fos-4-fresnel/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/etc/fos-4-fresnel/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Zoom range envelope is documented; the extended depth is used for a conservative outer bound.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.
- No official product image URL was present in the research CSV.

## Detailed model revision

Revision 2 uses a `fresnel` profile with 52 visible meshes and 22,744 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/etc/fos-4-fresnel/validation/detail.json) · [Front](../../../../assets/fixtures/etc/fos-4-fresnel/previews/front.png) · [Side](../../../../assets/fixtures/etc/fos-4-fresnel/previews/side.png) · [Rear](../../../../assets/fixtures/etc/fos-4-fresnel/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/etc/fos-4-fresnel/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/etc/fos-4-fresnel/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
