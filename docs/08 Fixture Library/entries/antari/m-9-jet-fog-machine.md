# Antari M-9 Jet Fog Machine

- Library state: `ready_for_visualization`
- Identity: model `M-9`; atmospherics / LED-equipped heated fog jet
- Official source: [https://antari.com/products/m-9/](https://antari.com/products/m-9/) (accessed 2026-09-30)
- Reference envelope: 0.3210 m W × 0.4200 m H × 0.3930 m D
- Control: See source-backed protocol list; compatibility and control system are not implemented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/antari/m-9-jet-fog-machine/fixture.json)
- [Blender model](../../../../assets/fixtures/antari/m-9-jet-fog-machine/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/antari/m-9-jet-fog-machine/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/antari/m-9-jet-fog-machine/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Manufacturer labels L/W/H; W mapped lateral and L depth. Official product image inspected, but image pose is not itself a dimensional drawing.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `jet` profile with 88 visible meshes and 12,944 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/antari/m-9-jet-fog-machine/validation/detail.json) · [Front](../../../../assets/fixtures/antari/m-9-jet-fog-machine/previews/front.png) · [Side](../../../../assets/fixtures/antari/m-9-jet-fog-machine/previews/side.png) · [Rear](../../../../assets/fixtures/antari/m-9-jet-fog-machine/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/antari/m-9-jet-fog-machine/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/antari/m-9-jet-fog-machine/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
