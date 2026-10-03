# ROBE Lighting PAINTE

- Library state: `ready_for_visualization`
- Identity: model `PAINTE`; moving light / white-source spot/profile/beam
- Official source: [https://www.robe.cz/painte](https://www.robe.cz/painte) (accessed 2026-10-02)
- Reference envelope: 0.3670 m W × 0.6190 m H × 0.2190 m D
- Control: DMX512, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/robe-lighting/painte/fixture.json)
- [Blender model](../../../../assets/fixtures/robe-lighting/painte/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/robe-lighting/painte/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/robe-lighting/painte/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Product page dimensions; depth specified with head vertical.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 17,996 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/robe-lighting/painte/validation/detail.json) · [Front](../../../../assets/fixtures/robe-lighting/painte/previews/front.png) · [Side](../../../../assets/fixtures/robe-lighting/painte/previews/side.png) · [Rear](../../../../assets/fixtures/robe-lighting/painte/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/robe-lighting/painte/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/robe-lighting/painte/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
