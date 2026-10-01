# MDG ATMOSPHERE APS Haze Generator

- Library state: `ready_for_visualization`
- Identity: model `ATMOSPHERE APS`; atmospherics / oil-based compressor hazer
- Official source: [https://www.mdgfog.com/en/atmosphereaps](https://www.mdgfog.com/en/atmosphereaps) (accessed 2026-09-30)
- Reference envelope: 0.1800 m W × 0.3000 m H × 0.6850 m D
- Control: See source-backed protocol list; compatibility and control system are not implemented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/mdg/atmosphere-aps-haze-generator/fixture.json)
- [Blender model](../../../../assets/fixtures/mdg/atmosphere-aps-haze-generator/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/mdg/atmosphere-aps-haze-generator/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/mdg/atmosphere-aps-haze-generator/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- MDG labels length, width and height explicitly; L mapped to depth. Front/angled official image inspected for body orientation.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `hazer` profile with 11 visible meshes and 1,492 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/mdg/atmosphere-aps-haze-generator/validation/detail.json) · [Front](../../../../assets/fixtures/mdg/atmosphere-aps-haze-generator/previews/front.png) · [Side](../../../../assets/fixtures/mdg/atmosphere-aps-haze-generator/previews/side.png) · [Rear](../../../../assets/fixtures/mdg/atmosphere-aps-haze-generator/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/mdg/atmosphere-aps-haze-generator/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/mdg/atmosphere-aps-haze-generator/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
