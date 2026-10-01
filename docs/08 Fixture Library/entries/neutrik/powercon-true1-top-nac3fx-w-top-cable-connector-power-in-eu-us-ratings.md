# Neutrik powerCON TRUE1 TOP NAC3FX-W-TOP cable connector (Power-In, EU/US ratings)

- Library state: `researched`
- Identity: model `NAC3FX-W-TOP`; mains_connector / locking single-phase Power-In cable connector, female, screw termination
- Official source: [https://www.neutrik.com/en/product/nac3fx-w-top](https://www.neutrik.com/en/product/nac3fx-w-top) (accessed 2026-09-30)
- Reference envelope: 0.0320 m W × 0.0320 m H × 0.0800 m D
- Control: Mains power connector component, not a DMX/data connector. Female cable connector identifies Power-In; mating inlet, cord conductors, regional wiring and protection are separate.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/neutrik/powercon-true1-top-nac3fx-w-top-cable-connector-power-in-eu-us-ratings/fixture.json)
- [Blender model](../../../../assets/fixtures/neutrik/powercon-true1-top-nac3fx-w-top-cable-connector-power-in-eu-us-ratings/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/neutrik/powercon-true1-top-nac3fx-w-top-cable-connector-power-in-eu-us-ratings/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/neutrik/powercon-true1-top-nac3fx-w-top-cable-connector-power-in-eu-us-ratings/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Model maximum 80 mm length and conservative 32 mm square end-view envelope from drawing; dimension drawing labels the end view 32 mm overall and 26.5 mm housing diameter. A circular/square conservative envelope is not an exact measured silhouette in both transverse axes.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `power_connector` profile with 16 visible meshes and 7,844 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/neutrik/powercon-true1-top-nac3fx-w-top-cable-connector-power-in-eu-us-ratings/validation/detail.json) · [Front](../../../../assets/fixtures/neutrik/powercon-true1-top-nac3fx-w-top-cable-connector-power-in-eu-us-ratings/previews/front.png) · [Side](../../../../assets/fixtures/neutrik/powercon-true1-top-nac3fx-w-top-cable-connector-power-in-eu-us-ratings/previews/side.png) · [Rear](../../../../assets/fixtures/neutrik/powercon-true1-top-nac3fx-w-top-cable-connector-power-in-eu-us-ratings/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/neutrik/powercon-true1-top-nac3fx-w-top-cable-connector-power-in-eu-us-ratings/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/neutrik/powercon-true1-top-nac3fx-w-top-cable-connector-power-in-eu-us-ratings/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
