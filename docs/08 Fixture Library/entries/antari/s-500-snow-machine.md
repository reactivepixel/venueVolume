# Antari S-500 Snow Machine

- Library state: `researched`
- Identity: model `S-500`; atmospherics / water-based snow effect machine
- Official source: [https://antari.com/products/s-500/](https://antari.com/products/s-500/) (accessed 2026-09-30)
- Reference envelope: 0.5510 m W × 0.6510 m H × 0.5920 m D
- Control: See source-backed protocol list; compatibility and control system are not implemented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/antari/s-500-snow-machine/fixture.json)
- [Blender model](../../../../assets/fixtures/antari/s-500-snow-machine/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/antari/s-500-snow-machine/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/antari/s-500-snow-machine/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Antari labels L/W/H = 592/551/651 mm for S-500, but the current product image shows the case open and the dimensions appear to be the protective case's transport envelope. Body orientation mapping follows L/W/H; pose is estimated closed case.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `snow` profile with 23 visible meshes and 3,940 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/antari/s-500-snow-machine/validation/detail.json) · [Front](../../../../assets/fixtures/antari/s-500-snow-machine/previews/front.png) · [Side](../../../../assets/fixtures/antari/s-500-snow-machine/previews/side.png) · [Rear](../../../../assets/fixtures/antari/s-500-snow-machine/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/antari/s-500-snow-machine/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/antari/s-500-snow-machine/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
