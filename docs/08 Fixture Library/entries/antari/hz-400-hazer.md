# Antari HZ-400 Hazer

- Library state: `ready_for_visualization`
- Identity: model `HZ-400`; equipment / oil-based haze generator
- Official source: [https://antari.com/products/hz-400/](https://antari.com/products/hz-400/) (accessed 2026-10-02)
- Reference envelope: 0.3200 m W × 0.3250 m H × 0.5100 m D
- Control: DMX512, manual, timer, optional wireless; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/antari/hz-400-hazer/fixture.json)
- [Blender model](../../../../assets/fixtures/antari/hz-400-hazer/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/antari/hz-400-hazer/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/antari/hz-400-hazer/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer L/W/H = 510/320/325 mm mapped to depth/width/height.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `hazer` profile with 18 visible meshes and 3,000 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/antari/hz-400-hazer/validation/detail.json) · [Front](../../../../assets/fixtures/antari/hz-400-hazer/previews/front.png) · [Side](../../../../assets/fixtures/antari/hz-400-hazer/previews/side.png) · [Rear](../../../../assets/fixtures/antari/hz-400-hazer/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/antari/hz-400-hazer/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/antari/hz-400-hazer/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
