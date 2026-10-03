# MAGIC FX CO2 JET II

- Library state: `researched`
- Identity: model `MFX1118`; atmospherics / liquid CO2 gas jet
- Official source: [https://magicfx.com/products/co2jet-ii](https://magicfx.com/products/co2jet-ii) (accessed 2026-09-30)
- Reference envelope: 0.2320 m W × 0.1245 m H × 0.1960 m D
- Control: See source-backed protocol list; compatibility and control system are not implemented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/magic-fx/co2-jet-ii/fixture.json)
- [Blender model](../../../../assets/fixtures/magic-fx/co2-jet-ii/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/magic-fx/co2-jet-ii/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/magic-fx/co2-jet-ii/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Manufacturer documents main dimensions length 232 mm, width 196 mm, height 124.5 mm. Image-based pose maps length to width and manual width to depth; this axis assignment is estimated from the official view. Page triplet 290 x 290 x 200 mm is packaging, corroborated by manual package dimensions 289 x 289 x 201 mm; the manual's appliance dimensions are used. Integration review maps main length to front width using product photos. The rear-facing metal fitting is a gas inlet, not a horizontal output nozzle. Envelope axes/pose are estimated.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `co2_jet` profile with 12 visible meshes and 1,680 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/magic-fx/co2-jet-ii/validation/detail.json) · [Front](../../../../assets/fixtures/magic-fx/co2-jet-ii/previews/front.png) · [Side](../../../../assets/fixtures/magic-fx/co2-jet-ii/previews/side.png) · [Rear](../../../../assets/fixtures/magic-fx/co2-jet-ii/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/magic-fx/co2-jet-ii/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/magic-fx/co2-jet-ii/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
