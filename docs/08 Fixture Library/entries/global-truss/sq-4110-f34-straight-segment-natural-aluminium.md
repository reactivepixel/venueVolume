# Global Truss SQ-4110 F34 Straight Segment, Natural Aluminium

- Library state: `ready_for_visualization`
- Identity: model `F340066`; square_truss_segment / one-meter F34 square aluminum truss section
- Official source: [https://www.globaltruss.com/sq-4110](https://www.globaltruss.com/sq-4110) (accessed 2026-09-30)
- Reference envelope: 1.0000 m W × 0.2900 m H × 0.2900 m D
- Control: Passive mechanical support; no DMX, network, or electrical control connection.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/global-truss/sq-4110-f34-straight-segment-natural-aluminium/fixture.json)
- [Blender model](../../../../assets/fixtures/global-truss/sq-4110-f34-straight-segment-natural-aluminium/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/global-truss/sq-4110-f34-straight-segment-natural-aluminium/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/global-truss/sq-4110-f34-straight-segment-natural-aluminium/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- 1 m overall length x 290 x 290 mm external square section
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `truss` profile with 20 visible meshes and 2,608 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/global-truss/sq-4110-f34-straight-segment-natural-aluminium/validation/detail.json) · [Front](../../../../assets/fixtures/global-truss/sq-4110-f34-straight-segment-natural-aluminium/previews/front.png) · [Side](../../../../assets/fixtures/global-truss/sq-4110-f34-straight-segment-natural-aluminium/previews/side.png) · [Rear](../../../../assets/fixtures/global-truss/sq-4110-f34-straight-segment-natural-aluminium/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/global-truss/sq-4110-f34-straight-segment-natural-aluminium/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/global-truss/sq-4110-f34-straight-segment-natural-aluminium/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
