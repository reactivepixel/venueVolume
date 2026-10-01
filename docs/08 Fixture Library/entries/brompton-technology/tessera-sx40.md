# Brompton Technology Tessera SX40

- Library state: `ready_for_visualization`
- Identity: model `SX40`; led_video_processor / LED display processor for video ingest and panel mapping
- Official source: [https://www.bromptontech.com/product/sx40/](https://www.bromptontech.com/product/sx40/) (accessed 2026-09-30)
- Reference envelope: 0.4826 m W × 0.0889 m H × 0.4064 m D
- Control: Video input and LED-panel data output; processor also supports DMX-512A and sACN lighting control integration, which is distinct from the video output path.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/brompton-technology/tessera-sx40/fixture.json)
- [Blender model](../../../../assets/fixtures/brompton-technology/tessera-sx40/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/brompton-technology/tessera-sx40/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/brompton-technology/tessera-sx40/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- 482.6 W x 88.9 H x 406.4 L mm unboxed
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `media_server` profile with 33 visible meshes and 5,820 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/brompton-technology/tessera-sx40/validation/detail.json) · [Front](../../../../assets/fixtures/brompton-technology/tessera-sx40/previews/front.png) · [Side](../../../../assets/fixtures/brompton-technology/tessera-sx40/previews/side.png) · [Rear](../../../../assets/fixtures/brompton-technology/tessera-sx40/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/brompton-technology/tessera-sx40/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/brompton-technology/tessera-sx40/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
