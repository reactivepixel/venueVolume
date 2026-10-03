# Doughty Engineering Doughty Quick Link-10mm-550Kg

- Library state: `researched`
- Identity: model `T23505`; atmospherics / rated secondary-suspension quick link
- Official source: [https://doughty-engineering.co.uk/products/quick-link-10mm-550kg/](https://doughty-engineering.co.uk/products/quick-link-10mm-550kg/) (accessed 2026-09-30)
- Reference envelope: 0.0900 m W × 0.0440 m H × 0.0160 m D
- Control: See source-backed protocol list; compatibility and control system are not implemented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/doughty-engineering/doughty-quick-link-10mm-550kg/fixture.json)
- [Blender model](../../../../assets/fixtures/doughty-engineering/doughty-quick-link-10mm-550kg/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/doughty-engineering/doughty-quick-link-10mm-550kg/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/doughty-engineering/doughty-quick-link-10mm-550kg/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Estimated outer 90 x 44 x 16 mm from orthographic manufacturer drawing: 70 mm inner length and 20 mm inner clear height, calibrated with 10 mm bar diameter; closure sleeve measures about 1.6x rod diameter in the side view and raises the silhouette about 4 mm beyond the 40 mm loop estimate. These are drawing-calibrated visual bounds, not published outer dimensions or certified clearances. Raw 70/20/11/10 mm measures retained above. Product page says 550 kg while data sheet says WLL 500 kg; appearance research only, not load selection.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `safety_hardware` profile with 3 visible meshes and 1,728 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/doughty-engineering/doughty-quick-link-10mm-550kg/validation/detail.json) · [Front](../../../../assets/fixtures/doughty-engineering/doughty-quick-link-10mm-550kg/previews/front.png) · [Side](../../../../assets/fixtures/doughty-engineering/doughty-quick-link-10mm-550kg/previews/side.png) · [Rear](../../../../assets/fixtures/doughty-engineering/doughty-quick-link-10mm-550kg/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/doughty-engineering/doughty-quick-link-10mm-550kg/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/doughty-engineering/doughty-quick-link-10mm-550kg/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
