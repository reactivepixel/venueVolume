# Eliminator Lighting (ADJ Group) MBMHD3 mirror ball motor

- Library state: `ready_for_visualization`
- Identity: model `MBMHD3`; mirror_motor / Non-DMX plug-in motor for separate mirror ball, up to 500 mm
- Official source: [https://www.adj.com/products/mbmhd3](https://www.adj.com/products/mbmhd3) (accessed 2026-09-30)
- Reference envelope: 0.1360 m W × 0.0800 m H × 0.1360 m D
- Control: Mains-powered fixed-speed motor; separate ball
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/eliminator-lighting-adj-group/mbmhd3-mirror-ball-motor/fixture.json)
- [Blender model](../../../../assets/fixtures/eliminator-lighting-adj-group/mbmhd3-mirror-ball-motor/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/eliminator-lighting-adj-group/mbmhd3-mirror-ball-motor/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/eliminator-lighting-adj-group/mbmhd3-mirror-ball-motor/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Motor enclosure dimensions only; ball is separate.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `mirror_motor` profile with 4 visible meshes and 656 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/eliminator-lighting-adj-group/mbmhd3-mirror-ball-motor/validation/detail.json) · [Front](../../../../assets/fixtures/eliminator-lighting-adj-group/mbmhd3-mirror-ball-motor/previews/front.png) · [Side](../../../../assets/fixtures/eliminator-lighting-adj-group/mbmhd3-mirror-ball-motor/previews/side.png) · [Rear](../../../../assets/fixtures/eliminator-lighting-adj-group/mbmhd3-mirror-ball-motor/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/eliminator-lighting-adj-group/mbmhd3-mirror-ball-motor/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/eliminator-lighting-adj-group/mbmhd3-mirror-ball-motor/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
