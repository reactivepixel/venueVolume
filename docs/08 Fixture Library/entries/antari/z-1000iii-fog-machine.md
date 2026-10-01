# Antari Z-1000III Fog Machine

- Library state: `ready_for_visualization`
- Identity: model `Z-1000III`; atmospherics / heated water-based fogger
- Official source: [https://antari.com/products/z-1000iii/](https://antari.com/products/z-1000iii/) (accessed 2026-09-30)
- Reference envelope: 0.2810 m W × 0.2660 m H × 0.4330 m D
- Control: See source-backed protocol list; compatibility and control system are not implemented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/antari/z-1000iii-fog-machine/fixture.json)
- [Blender model](../../../../assets/fixtures/antari/z-1000iii-fog-machine/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/antari/z-1000iii-fog-machine/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/antari/z-1000iii-fog-machine/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Manufacturer labels L/W/H; L mapped to depth in the upright front-facing pose.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `fogger` profile with 26 visible meshes and 2,568 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/antari/z-1000iii-fog-machine/validation/detail.json) · [Front](../../../../assets/fixtures/antari/z-1000iii-fog-machine/previews/front.png) · [Side](../../../../assets/fixtures/antari/z-1000iii-fog-machine/previews/side.png) · [Rear](../../../../assets/fixtures/antari/z-1000iii-fog-machine/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/antari/z-1000iii-fog-machine/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/antari/z-1000iii-fog-machine/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
