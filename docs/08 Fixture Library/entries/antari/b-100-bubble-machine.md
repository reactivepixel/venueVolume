# Antari B-100 Bubble Machine

- Library state: `ready_for_visualization`
- Identity: model `B-100`; atmospherics / DMX bubble machine
- Official source: [https://antari.com/products/b-100/](https://antari.com/products/b-100/) (accessed 2026-09-30)
- Reference envelope: 0.2650 m W × 0.2900 m H × 0.3410 m D
- Control: See source-backed protocol list; compatibility and control system are not implemented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/antari/b-100-bubble-machine/fixture.json)
- [Blender model](../../../../assets/fixtures/antari/b-100-bubble-machine/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/antari/b-100-bubble-machine/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/antari/b-100-bubble-machine/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Current product page and current Rev. 05 manual agree on manufacturer L/W/H = 341/265/290 mm; dimensions refer to the B-100 variant.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `bubble` profile with 22 visible meshes and 10,712 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/antari/b-100-bubble-machine/validation/detail.json) · [Front](../../../../assets/fixtures/antari/b-100-bubble-machine/previews/front.png) · [Side](../../../../assets/fixtures/antari/b-100-bubble-machine/previews/side.png) · [Rear](../../../../assets/fixtures/antari/b-100-bubble-machine/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/antari/b-100-bubble-machine/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/antari/b-100-bubble-machine/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
