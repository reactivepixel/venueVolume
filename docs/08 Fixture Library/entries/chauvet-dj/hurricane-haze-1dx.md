# CHAUVET DJ Hurricane Haze 1DX

- Library state: `researched`
- Identity: model `Hurricane Haze 1DX`; atmospherics / water-based heated hazer
- Official source: [https://fr.chauvetdj.com/products/hurricane-haze-1dx/](https://fr.chauvetdj.com/products/hurricane-haze-1dx/) (accessed 2026-09-30)
- Reference envelope: 0.1500 m W × 0.2230 m H × 0.2780 m D
- Control: See source-backed protocol list; compatibility and control system are not implemented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chauvet-dj/hurricane-haze-1dx/fixture.json)
- [Blender model](../../../../assets/fixtures/chauvet-dj/hurricane-haze-1dx/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chauvet-dj/hurricane-haze-1dx/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chauvet-dj/hurricane-haze-1dx/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Manufacturer lists 278 x 150 x 223 mm without labels; mapped largest axis to depth and shortest to width based on upright product view. Numeric dimensions are preserved; width/depth mapping is estimated.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `hazer` profile with 62 visible meshes and 10,648 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/chauvet-dj/hurricane-haze-1dx/validation/detail.json) · [Front](../../../../assets/fixtures/chauvet-dj/hurricane-haze-1dx/previews/front.png) · [Side](../../../../assets/fixtures/chauvet-dj/hurricane-haze-1dx/previews/side.png) · [Rear](../../../../assets/fixtures/chauvet-dj/hurricane-haze-1dx/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/chauvet-dj/hurricane-haze-1dx/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chauvet-dj/hurricane-haze-1dx/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
