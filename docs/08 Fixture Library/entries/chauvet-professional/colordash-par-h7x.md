# CHAUVET Professional COLORdash PAR H7X

- Library state: `researched`
- Identity: model `COLORDASHPARH7X`; par / RGBWAUV compact LED wash
- Official source: [https://chauvetprofessional.com/product/colordash-par-h7x/](https://chauvetprofessional.com/product/colordash-par-h7x/) (accessed 2026-09-30)
- Reference envelope: 0.2580 m W × 0.2400 m H × 0.1160 m D
- Control: DMX, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chauvet-professional/colordash-par-h7x/fixture.json)
- [Blender model](../../../../assets/fixtures/chauvet-professional/colordash-par-h7x/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chauvet-professional/colordash-par-h7x/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chauvet-professional/colordash-par-h7x/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- The manufacturer documents the three extents (258 x 240 x 116 mm) but not their axis order in page text; assigned front width x assembled vertical height x front-to-back depth from product views; confirm against linked 2D CAD before modeling.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.
- Source describes a vertical-head dimensional pose; modeled horizontal optical-axis pose fits that envelope. Verify pose-specific shape before placement/clearance use.

## Detailed model revision

Revision 2 uses a `par` profile with 62 visible meshes and 22,212 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/chauvet-professional/colordash-par-h7x/validation/detail.json) · [Front](../../../../assets/fixtures/chauvet-professional/colordash-par-h7x/previews/front.png) · [Side](../../../../assets/fixtures/chauvet-professional/colordash-par-h7x/previews/side.png) · [Rear](../../../../assets/fixtures/chauvet-professional/colordash-par-h7x/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/chauvet-professional/colordash-par-h7x/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chauvet-professional/colordash-par-h7x/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
