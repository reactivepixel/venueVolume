# Antari HZ-500 Hazer

- Library state: `researched`
- Identity: model `HZ-500`; equipment / oil-based haze generator
- Official source: [https://antari.com/products/hz-500/](https://antari.com/products/hz-500/) (accessed 2026-10-02)
- Reference envelope: 0.3750 m W × 0.3550 m H × 0.5150 m D
- Control: DMX512, manual, timer; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/antari/hz-500-hazer/fixture.json)
- [Blender model](../../../../assets/fixtures/antari/hz-500-hazer/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/antari/hz-500-hazer/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/antari/hz-500-hazer/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer L/W/H = 515/375/355 mm, mapped to depth/width/height for the integrated case in its normal upright pose.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `hazer` profile with 37 visible meshes and 6,956 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/antari/hz-500-hazer/validation/detail.json) · [Front](../../../../assets/fixtures/antari/hz-500-hazer/previews/front.png) · [Side](../../../../assets/fixtures/antari/hz-500-hazer/previews/side.png) · [Rear](../../../../assets/fixtures/antari/hz-500-hazer/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/antari/hz-500-hazer/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/antari/hz-500-hazer/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
