# ETC Desire D60

- Library state: `researched`
- Identity: model `D60`; Architectural wash / LED wash
- Official source: [https://www.etcconnect.com/workarea/DownloadAsset.aspx?id=10737512649](https://www.etcconnect.com/workarea/DownloadAsset.aspx?id=10737512649) (accessed 2026-09-30)
- Reference envelope: 0.3090 m W × 0.3610 m H × 0.2900 m D
- Control: DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/etc/desire-d60/fixture.json)
- [Blender model](../../../../assets/fixtures/etc/desire-d60/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/etc/desire-d60/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/etc/desire-d60/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Maximum overall dimensions are documented; H/W/depth assignment follows the assembled fixture drawing.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.
- No official product image URL was present in the research CSV.

## Detailed model revision

Revision 2 uses a `par` profile with 221 visible meshes and 77,756 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/etc/desire-d60/validation/detail.json) · [Front](../../../../assets/fixtures/etc/desire-d60/previews/front.png) · [Side](../../../../assets/fixtures/etc/desire-d60/previews/side.png) · [Rear](../../../../assets/fixtures/etc/desire-d60/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/etc/desire-d60/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/etc/desire-d60/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
