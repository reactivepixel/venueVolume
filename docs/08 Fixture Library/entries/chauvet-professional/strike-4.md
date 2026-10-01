# CHAUVET Professional STRIKE 4

- Library state: `researched`
- Identity: model `STRIKE4`; blinder / Four-cell tungsten-style audience blinder/strobe
- Official source: [https://chauvetprofessional.com/product/strike-4/](https://chauvetprofessional.com/product/strike-4/) (accessed 2026-09-30)
- Reference envelope: 0.3620 m W × 0.3620 m H × 0.1630 m D
- Control: DMX
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chauvet-professional/strike-4/fixture.json)
- [Blender model](../../../../assets/fixtures/chauvet-professional/strike-4/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chauvet-professional/strike-4/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chauvet-professional/strike-4/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Manufacturer LxWxH values 362 x 362 x 163 mm map to square face width/height and depth with emitting face forward. Neutral-pose axis assignment is image-inferred, not established by a labelled drawing.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `blinder` profile with 53 visible meshes and 8,828 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/chauvet-professional/strike-4/validation/detail.json) · [Front](../../../../assets/fixtures/chauvet-professional/strike-4/previews/front.png) · [Side](../../../../assets/fixtures/chauvet-professional/strike-4/previews/side.png) · [Rear](../../../../assets/fixtures/chauvet-professional/strike-4/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/chauvet-professional/strike-4/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chauvet-professional/strike-4/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
