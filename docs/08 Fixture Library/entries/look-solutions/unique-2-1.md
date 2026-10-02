# Look Solutions Unique 2.1

- Library state: `ready_for_visualization`
- Identity: model `Unique 2.1`; equipment / water-based hazer
- Official source: [https://www.looksolutions.com/products/unique_2_1/8.html](https://www.looksolutions.com/products/unique_2_1/8.html) (accessed 2026-10-02)
- Reference envelope: 0.2500 m W × 0.2500 m H × 0.4700 m D
- Control: DMX512, 0–10 V analog, standalone, internal timer; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/look-solutions/unique-2-1/fixture.json)
- [Blender model](../../../../assets/fixtures/look-solutions/unique-2-1/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/look-solutions/unique-2-1/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/look-solutions/unique-2-1/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer L/W/H = 470/250/250 mm; no flight case included.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `hazer` profile with 48 visible meshes and 8,640 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/look-solutions/unique-2-1/validation/detail.json) · [Front](../../../../assets/fixtures/look-solutions/unique-2-1/previews/front.png) · [Side](../../../../assets/fixtures/look-solutions/unique-2-1/previews/side.png) · [Rear](../../../../assets/fixtures/look-solutions/unique-2-1/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/look-solutions/unique-2-1/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/look-solutions/unique-2-1/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
