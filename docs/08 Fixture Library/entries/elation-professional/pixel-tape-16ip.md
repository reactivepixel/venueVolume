# Elation Professional PIXEL TAPE 16IP

- Library state: `ready_for_visualization`
- Identity: model `PIX618`; pixel_strip / 2.72 m IP65 RGB pixel tape module, driver required
- Official source: [https://www.elationlighting.com/products/pixel-tape-16ip](https://www.elationlighting.com/products/pixel-tape-16ip) (accessed 2026-09-30)
- Reference envelope: 2.7200 m W × 0.0030 m H × 0.0120 m D
- Control: External Elation pixel driver; driver translates DMX to APA102 pixel data
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/elation-professional/pixel-tape-16ip/fixture.json)
- [Blender model](../../../../assets/fixtures/elation-professional/pixel-tape-16ip/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/elation-professional/pixel-tape-16ip/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/elation-professional/pixel-tape-16ip/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Manufacturer specified module length and cross-section.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `pixel_strip` profile with 341 visible meshes and 4,092 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/elation-professional/pixel-tape-16ip/validation/detail.json) · [Front](../../../../assets/fixtures/elation-professional/pixel-tape-16ip/previews/front.png) · [Side](../../../../assets/fixtures/elation-professional/pixel-tape-16ip/previews/side.png) · [Rear](../../../../assets/fixtures/elation-professional/pixel-tape-16ip/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/elation-professional/pixel-tape-16ip/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/elation-professional/pixel-tape-16ip/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
