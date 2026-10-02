# Antari B-200 Bubble Machine

- Library state: `researched`
- Identity: model `B-200`; equipment / high-output bubble machine
- Official source: [https://antari.com/products/b-200/](https://antari.com/products/b-200/) (accessed 2026-10-02)
- Reference envelope: 0.5080 m W × 0.3910 m H × 0.2510 m D
- Control: DMX512, manual, optional timer, optional wireless, optional cable remote; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/antari/b-200-bubble-machine/fixture.json)
- [Blender model](../../../../assets/fixtures/antari/b-200-bubble-machine/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/antari/b-200-bubble-machine/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/antari/b-200-bubble-machine/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer L/W/H = 508/251/391 mm mapped to depth/width/height.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `bubble` profile with 95 visible meshes and 62,588 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/antari/b-200-bubble-machine/validation/detail.json) · [Front](../../../../assets/fixtures/antari/b-200-bubble-machine/previews/front.png) · [Side](../../../../assets/fixtures/antari/b-200-bubble-machine/previews/side.png) · [Rear](../../../../assets/fixtures/antari/b-200-bubble-machine/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/antari/b-200-bubble-machine/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/antari/b-200-bubble-machine/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
