# MAGIC FX CO2 Bottle To Hose Connector

- Library state: `ready_for_visualization`
- Identity: model `MFX1103`; atmospherics / CO2 cylinder-to-hose connector
- Official source: [https://magicfx.com/products/co2-bottle-to-hose-connector](https://magicfx.com/products/co2-bottle-to-hose-connector) (accessed 2026-09-30)
- Reference envelope: 0.0300 m W × 0.0300 m H × 0.1500 m D
- Control: See source-backed protocol list; compatibility and control system are not implemented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/magic-fx/co2-bottle-to-hose-connector/fixture.json)
- [Blender model](../../../../assets/fixtures/magic-fx/co2-bottle-to-hose-connector/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/magic-fx/co2-bottle-to-hose-connector/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/magic-fx/co2-bottle-to-hose-connector/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Product page gives length/width/height 150/30/30 mm; length is mapped to the connector's long axis in the official photo.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `co2_supply` profile with 21 visible meshes and 12,648 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/magic-fx/co2-bottle-to-hose-connector/validation/detail.json) · [Front](../../../../assets/fixtures/magic-fx/co2-bottle-to-hose-connector/previews/front.png) · [Side](../../../../assets/fixtures/magic-fx/co2-bottle-to-hose-connector/previews/side.png) · [Rear](../../../../assets/fixtures/magic-fx/co2-bottle-to-hose-connector/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/magic-fx/co2-bottle-to-hose-connector/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/magic-fx/co2-bottle-to-hose-connector/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
