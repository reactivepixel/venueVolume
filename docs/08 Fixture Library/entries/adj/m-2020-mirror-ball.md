# ADJ M-2020 Mirror Ball

- Library state: `ready_for_visualization`
- Identity: model `M-2020`; mirror_ball / 20-inch spherical mirror ball; motor sold separately
- Official source: [https://www.adj.com/m-2020](https://www.adj.com/m-2020) (accessed 2026-09-30)
- Reference envelope: 0.5080 m W × 0.5080 m H × 0.5080 m D
- Control: Passive reflective accessory; requires separately rated motor and suspension
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/m-2020-mirror-ball/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/m-2020-mirror-ball/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/m-2020-mirror-ball/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/m-2020-mirror-ball/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Manufacturer gives 20-inch sphere dimensions and 6.8 kg mass; sphere diameter used for each axis. Only the 508 mm sphere is modeled; hanging hardware is omitted.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `mirror_ball` profile with 33 visible meshes and 19,664 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/adj/m-2020-mirror-ball/validation/detail.json) · [Front](../../../../assets/fixtures/adj/m-2020-mirror-ball/previews/front.png) · [Side](../../../../assets/fixtures/adj/m-2020-mirror-ball/previews/side.png) · [Rear](../../../../assets/fixtures/adj/m-2020-mirror-ball/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/adj/m-2020-mirror-ball/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/m-2020-mirror-ball/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
