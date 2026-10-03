# MAGIC FX Powershot II

- Library state: `ready_for_visualization`
- Identity: model `MFX0304`; atmospherics / electric confetti / streamer shot launcher
- Official source: [https://magicfx.com/products/powershot-ii](https://magicfx.com/products/powershot-ii) (accessed 2026-09-30)
- Reference envelope: 0.1270 m W × 0.1900 m H × 0.0900 m D
- Control: See source-backed protocol list; compatibility and control system are not implemented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/magic-fx/powershot-ii/fixture.json)
- [Blender model](../../../../assets/fixtures/magic-fx/powershot-ii/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/magic-fx/powershot-ii/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/magic-fx/powershot-ii/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Manufacturer labels length/width/height; image checked in compact upright mounting pose, length treated as front-to-back short axis.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `confetti` profile with 5 visible meshes and 844 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/magic-fx/powershot-ii/validation/detail.json) · [Front](../../../../assets/fixtures/magic-fx/powershot-ii/previews/front.png) · [Side](../../../../assets/fixtures/magic-fx/powershot-ii/previews/side.png) · [Rear](../../../../assets/fixtures/magic-fx/powershot-ii/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/magic-fx/powershot-ii/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/magic-fx/powershot-ii/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
