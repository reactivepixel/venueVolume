# ROBE Lighting ColorWash 575 AT

- Library state: `researched`
- Identity: model `ColorWash 575 AT`; moving light / wash
- Official source: [https://www.robe.cz/colorwash-575-at-tm](https://www.robe.cz/colorwash-575-at-tm) (accessed 2026-10-02)
- Reference envelope: 0.4700 m W × 0.5880 m H × 0.4460 m D
- Control: USITT DMX-512, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/robe-lighting/colorwash-575-at/fixture.json)
- [Blender model](../../../../assets/fixtures/robe-lighting/colorwash-575-at/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/robe-lighting/colorwash-575-at/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/robe-lighting/colorwash-575-at/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Robe mechanical specification: width 470 mm, height 588 mm with head horizontal, depth 446 mm.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 82 visible meshes and 26,200 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/robe-lighting/colorwash-575-at/validation/detail.json) · [Front](../../../../assets/fixtures/robe-lighting/colorwash-575-at/previews/front.png) · [Side](../../../../assets/fixtures/robe-lighting/colorwash-575-at/previews/side.png) · [Rear](../../../../assets/fixtures/robe-lighting/colorwash-575-at/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/robe-lighting/colorwash-575-at/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/robe-lighting/colorwash-575-at/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
