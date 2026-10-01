# Global Truss GT-Stage-Adjust 1 x 2 m

- Library state: `researched`
- Identity: model `STG0004`; stage_deck / adjustable-height modular stage platform
- Official source: [https://www.globaltruss.com/gt-stage-adjust](https://www.globaltruss.com/gt-stage-adjust) (accessed 2026-09-30)
- Reference envelope: 2.0000 m W × 0.9779 m H × 1.0000 m D
- Control: Passive structural scenic platform; no electrical or DMX connection.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/global-truss/gt-stage-adjust-1-x-2-m/fixture.json)
- [Blender model](../../../../assets/fixtures/global-truss/gt-stage-adjust-1-x-2-m/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/global-truss/gt-stage-adjust-1-x-2-m/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/global-truss/gt-stage-adjust-1-x-2-m/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Platform footprint is documented. Maximum adjustable height is uncertain because the current product page says 38.5 in (0.9779 m) while the 2019 catalog says 39 in (0.9906 m); retained current-page value as representative configuration.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `deck` profile with 14 visible meshes and 2,632 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/global-truss/gt-stage-adjust-1-x-2-m/validation/detail.json) · [Front](../../../../assets/fixtures/global-truss/gt-stage-adjust-1-x-2-m/previews/front.png) · [Side](../../../../assets/fixtures/global-truss/gt-stage-adjust-1-x-2-m/previews/side.png) · [Rear](../../../../assets/fixtures/global-truss/gt-stage-adjust-1-x-2-m/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/global-truss/gt-stage-adjust-1-x-2-m/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/global-truss/gt-stage-adjust-1-x-2-m/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
