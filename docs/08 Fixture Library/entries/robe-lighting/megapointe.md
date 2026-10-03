# ROBE Lighting MegaPointe

- Library state: `ready_for_visualization`
- Identity: model `MegaPointe`; Moving head / hybrid beam spot wash
- Official source: [https://www.robe.cz/megapointe](https://www.robe.cz/megapointe) (accessed 2026-09-30)
- Reference envelope: 0.3960 m W × 0.6400 m H × 0.2300 m D
- Control: DMX, RDM, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/robe-lighting/megapointe/fixture.json)
- [Blender model](../../../../assets/fixtures/robe-lighting/megapointe/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/robe-lighting/megapointe/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/robe-lighting/megapointe/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer specifies H x W x D.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 17,996 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/robe-lighting/megapointe/validation/detail.json) · [Front](../../../../assets/fixtures/robe-lighting/megapointe/previews/front.png) · [Side](../../../../assets/fixtures/robe-lighting/megapointe/previews/side.png) · [Rear](../../../../assets/fixtures/robe-lighting/megapointe/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/robe-lighting/megapointe/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/robe-lighting/megapointe/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
