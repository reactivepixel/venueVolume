# ROBE Lighting LEDBeam 350

- Library state: `ready_for_visualization`
- Identity: model `LEDBeam 350`; Moving head / wide zoom wash
- Official source: [https://www.robe.cz/ledbeam-350](https://www.robe.cz/ledbeam-350) (accessed 2026-09-30)
- Reference envelope: 0.3200 m W × 0.4260 m H × 0.2200 m D
- Control: DMX, RDM, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/robe-lighting/ledbeam-350/fixture.json)
- [Blender model](../../../../assets/fixtures/robe-lighting/ledbeam-350/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/robe-lighting/ledbeam-350/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/robe-lighting/ledbeam-350/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer specifies H x W x D with head vertical.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 107 visible meshes and 30,780 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/robe-lighting/ledbeam-350/validation/detail.json) · [Front](../../../../assets/fixtures/robe-lighting/ledbeam-350/previews/front.png) · [Side](../../../../assets/fixtures/robe-lighting/ledbeam-350/previews/side.png) · [Rear](../../../../assets/fixtures/robe-lighting/ledbeam-350/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/robe-lighting/ledbeam-350/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/robe-lighting/ledbeam-350/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
