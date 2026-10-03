# CHAUVET Professional COLORdash Batten-Quad 6

- Library state: `researched`
- Identity: model `COLORBATTENQUAD6`; Batten / RGBW pixel bar
- Official source: [https://chauvetprofessional.com/product/colordash-batten-quad-6/](https://chauvetprofessional.com/product/colordash-batten-quad-6/) (accessed 2026-09-30)
- Reference envelope: 0.5600 m W × 0.1640 m H × 0.0650 m D
- Control: DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chauvet-professional/colordash-batten-quad-6/fixture.json)
- [Blender model](../../../../assets/fixtures/chauvet-professional/colordash-batten-quad-6/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chauvet-professional/colordash-batten-quad-6/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chauvet-professional/colordash-batten-quad-6/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Overall dimensions are documented; bar-length/height/depth axis assignment is inferred from product class and imagery.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `batten` profile with 50 visible meshes and 12,896 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/chauvet-professional/colordash-batten-quad-6/validation/detail.json) · [Front](../../../../assets/fixtures/chauvet-professional/colordash-batten-quad-6/previews/front.png) · [Side](../../../../assets/fixtures/chauvet-professional/colordash-batten-quad-6/previews/side.png) · [Rear](../../../../assets/fixtures/chauvet-professional/colordash-batten-quad-6/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/chauvet-professional/colordash-batten-quad-6/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chauvet-professional/colordash-batten-quad-6/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
