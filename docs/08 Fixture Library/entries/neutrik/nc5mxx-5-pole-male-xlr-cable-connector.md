# Neutrik NC5MXX 5-pole male XLR cable connector

- Library state: `ready_for_visualization`
- Identity: model `NC5MXX`; data_connector / 5-pole male XLR cable connector, nickel housing, silver contacts
- Official source: [https://www.neutrik.com/en/product/nc5mxx](https://www.neutrik.com/en/product/nc5mxx) (accessed 2026-09-30)
- Reference envelope: 0.0190 m W × 0.0190 m H × 0.0701 m D
- Control: Passive connector component for a 5-pole XLR data cable; it carries no active processing. Connector pinout and cable assembly are separate; do not identify this part as a terminator.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/neutrik/nc5mxx-5-pole-male-xlr-cable-connector/fixture.json)
- [Blender model](../../../../assets/fixtures/neutrik/nc5mxx-5-pole-male-xlr-cable-connector/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/neutrik/nc5mxx-5-pole-male-xlr-cable-connector/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/neutrik/nc5mxx-5-pole-male-xlr-cable-connector/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Circular cross-section is 19 mm maximum; longest manufacturer-dimensioned axis is 70.1 mm; use the maximum of its range.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `data_connector` profile with 17 visible meshes and 7,776 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/neutrik/nc5mxx-5-pole-male-xlr-cable-connector/validation/detail.json) · [Front](../../../../assets/fixtures/neutrik/nc5mxx-5-pole-male-xlr-cable-connector/previews/front.png) · [Side](../../../../assets/fixtures/neutrik/nc5mxx-5-pole-male-xlr-cable-connector/previews/side.png) · [Rear](../../../../assets/fixtures/neutrik/nc5mxx-5-pole-male-xlr-cable-connector/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/neutrik/nc5mxx-5-pole-male-xlr-cable-connector/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/neutrik/nc5mxx-5-pole-male-xlr-cable-connector/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
