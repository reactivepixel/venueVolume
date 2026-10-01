# CHAUVET Professional COLORdash Par-Quad 18

- Library state: `researched`
- Identity: model `COLORDASHPARQUAD18`; par / legacy RGBA LED wash
- Official source: [https://chauvetprofessional.com/product/colordash-par-quad-18/](https://chauvetprofessional.com/product/colordash-par-quad-18/) (accessed 2026-09-30)
- Reference envelope: 0.3230 m W × 0.2980 m H × 0.1060 m D
- Control: DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chauvet-professional/colordash-par-quad-18/fixture.json)
- [Blender model](../../../../assets/fixtures/chauvet-professional/colordash-par-quad-18/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chauvet-professional/colordash-par-quad-18/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chauvet-professional/colordash-par-quad-18/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer lists 323 x 298 x 106 mm but does not label axes in online specs; assignment uses front width, assembled height, and fixture depth from official manual's orthographic product views.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `par` profile with 95 visible meshes and 33,740 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/chauvet-professional/colordash-par-quad-18/validation/detail.json) · [Front](../../../../assets/fixtures/chauvet-professional/colordash-par-quad-18/previews/front.png) · [Side](../../../../assets/fixtures/chauvet-professional/colordash-par-quad-18/previews/side.png) · [Rear](../../../../assets/fixtures/chauvet-professional/colordash-par-quad-18/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/chauvet-professional/colordash-par-quad-18/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chauvet-professional/colordash-par-quad-18/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
