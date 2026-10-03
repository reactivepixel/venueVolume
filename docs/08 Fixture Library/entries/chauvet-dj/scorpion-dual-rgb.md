# CHAUVET DJ Scorpion Dual RGB

- Library state: `ready_for_visualization`
- Identity: model `Scorpion Dual RGB`; special effect / dual-aperture RGB laser projector
- Official source: [https://www.chauvetdj.com/products/scorpion-dual-rgb/](https://www.chauvetdj.com/products/scorpion-dual-rgb/) (accessed 2026-10-02)
- Reference envelope: 0.2160 m W × 0.1795 m H × 0.1610 m D
- Control: DMX (10-channel mode), IR remote (optional IRC-6), standalone, master/slave; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chauvet-dj/scorpion-dual-rgb/fixture.json)
- [Blender model](../../../../assets/fixtures/chauvet-dj/scorpion-dual-rgb/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chauvet-dj/scorpion-dual-rgb/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chauvet-dj/scorpion-dual-rgb/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manual product dimension drawing: 216 mm wide, 179.5 mm high, 161 mm deep; assembled housing on support feet.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `laser` profile with 62 visible meshes and 11,000 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/chauvet-dj/scorpion-dual-rgb/validation/detail.json) · [Front](../../../../assets/fixtures/chauvet-dj/scorpion-dual-rgb/previews/front.png) · [Side](../../../../assets/fixtures/chauvet-dj/scorpion-dual-rgb/previews/side.png) · [Rear](../../../../assets/fixtures/chauvet-dj/scorpion-dual-rgb/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/chauvet-dj/scorpion-dual-rgb/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chauvet-dj/scorpion-dual-rgb/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
