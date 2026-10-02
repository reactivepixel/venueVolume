# MDG ATMOSPHERE APS

- Library state: `ready_for_visualization`
- Identity: model `ATMOSPHERE APS`; equipment / CO2-driven haze generator
- Official source: [https://www.mdgfog.com/en/atmosphereaps](https://www.mdgfog.com/en/atmosphereaps) (accessed 2026-10-02)
- Reference envelope: 0.1800 m W × 0.3000 m H × 0.6850 m D
- Control: remote control, optional 2-channel DMX interface, optional remote timer; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/mdg/atmosphere-aps/fixture.json)
- [Blender model](../../../../assets/fixtures/mdg/atmosphere-aps/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/mdg/atmosphere-aps/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/mdg/atmosphere-aps/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- MDG labels length 68.5 cm, width 18 cm and height 30 cm; separate shipping weight explicitly includes flight case, while product dimensions identify the machine.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `hazer` profile with 11 visible meshes and 1,492 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/mdg/atmosphere-aps/validation/detail.json) · [Front](../../../../assets/fixtures/mdg/atmosphere-aps/previews/front.png) · [Side](../../../../assets/fixtures/mdg/atmosphere-aps/previews/side.png) · [Rear](../../../../assets/fixtures/mdg/atmosphere-aps/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/mdg/atmosphere-aps/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/mdg/atmosphere-aps/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
