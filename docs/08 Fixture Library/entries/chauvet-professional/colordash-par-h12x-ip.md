# CHAUVET Professional COLORdash PAR H12X IP

- Library state: `researched`
- Identity: model `COLORDASHPARH12XIP`; par / IP65 RGBWAUV LED wash
- Official source: [https://chauvetprofessional.com/product/colordash-par-h12x-ip/](https://chauvetprofessional.com/product/colordash-par-h12x-ip/) (accessed 2026-09-30)
- Reference envelope: 0.3054 m W × 0.2479 m H × 0.2320 m D
- Control: DMX, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chauvet-professional/colordash-par-h12x-ip/fixture.json)
- [Blender model](../../../../assets/fixtures/chauvet-professional/colordash-par-h12x-ip/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chauvet-professional/colordash-par-h12x-ip/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chauvet-professional/colordash-par-h12x-ip/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer documents extents in 9.1 x 12 x 9.8 in order but the page does not label axes; mapping them to front width, vertical assembled height, and body depth is an estimate pending CAD confirmation.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `par` profile with 77 visible meshes and 27,452 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/chauvet-professional/colordash-par-h12x-ip/validation/detail.json) · [Front](../../../../assets/fixtures/chauvet-professional/colordash-par-h12x-ip/previews/front.png) · [Side](../../../../assets/fixtures/chauvet-professional/colordash-par-h12x-ip/previews/side.png) · [Rear](../../../../assets/fixtures/chauvet-professional/colordash-par-h12x-ip/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/chauvet-professional/colordash-par-h12x-ip/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chauvet-professional/colordash-par-h12x-ip/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
