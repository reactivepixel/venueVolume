# ROBE Lighting RoboSpot MotionCamera

- Library state: `ready_for_visualization`
- Identity: model `RoboSpot MotionCamera`; followspot_camera_head / moving-head full-HD camera with 32x optical zoom for RoboSpot BaseStation
- Official source: [https://www.robelighting.com/robospot-motioncamera](https://www.robelighting.com/robospot-motioncamera) (accessed 2026-09-30)
- Reference envelope: 0.2770 m W × 0.3860 m H × 0.1470 m D
- Control: Moving camera head is controlled by DMX/RDM; camera video travels to RoboSpot BaseStation over Ethernet/Cat5. BaseStation is a separate equipment item.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/robe-lighting/robospot-motioncamera/fixture.json)
- [Blender model](../../../../assets/fixtures/robe-lighting/robospot-motioncamera/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/robe-lighting/robospot-motioncamera/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/robe-lighting/robospot-motioncamera/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Manufacturer mechanical dimensions; pose is head vertical.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `tracking_camera` profile with 16 visible meshes and 3,008 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/robe-lighting/robospot-motioncamera/validation/detail.json) · [Front](../../../../assets/fixtures/robe-lighting/robospot-motioncamera/previews/front.png) · [Side](../../../../assets/fixtures/robe-lighting/robospot-motioncamera/previews/side.png) · [Rear](../../../../assets/fixtures/robe-lighting/robospot-motioncamera/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/robe-lighting/robospot-motioncamera/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/robe-lighting/robospot-motioncamera/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
