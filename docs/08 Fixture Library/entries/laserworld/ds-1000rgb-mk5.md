# Laserworld DS-1000RGB MK5

- Library state: `ready_for_visualization`
- Identity: model `DS-1000RGB MK5`; laser / Class 4 RGB diode laser projector, physical asset only
- Official source: [https://www.laserworld.com/en/laserworld-ds/laserworld-ds-1000rgb-mk5](https://www.laserworld.com/en/laserworld-ds/laserworld-ds-1000rgb-mk5) (accessed 2026-09-30)
- Reference envelope: 0.2000 m W × 0.1250 m H × 0.1850 m D
- Control: Physical asset/specification only; no modeled aiming, safety implementation or firing instructions
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/laserworld/ds-1000rgb-mk5/fixture.json)
- [Blender model](../../../../assets/fixtures/laserworld/ds-1000rgb-mk5/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/laserworld/ds-1000rgb-mk5/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/laserworld/ds-1000rgb-mk5/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Model-specific manufacturer physical dimensions.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `laser` profile with 61 visible meshes and 10,524 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/laserworld/ds-1000rgb-mk5/validation/detail.json) · [Front](../../../../assets/fixtures/laserworld/ds-1000rgb-mk5/previews/front.png) · [Side](../../../../assets/fixtures/laserworld/ds-1000rgb-mk5/previews/side.png) · [Rear](../../../../assets/fixtures/laserworld/ds-1000rgb-mk5/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/laserworld/ds-1000rgb-mk5/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/laserworld/ds-1000rgb-mk5/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
