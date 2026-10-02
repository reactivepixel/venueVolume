# Look Solutions Tiny S

- Library state: `ready_for_visualization`
- Identity: model `Tiny S`; equipment / battery-powered handheld fog generator
- Official source: [https://www.looksolutions.com/products/tiny_s/8.html](https://www.looksolutions.com/products/tiny_s/8.html) (accessed 2026-10-02)
- Reference envelope: 0.0510 m W × 0.0350 m H × 0.1030 m D
- Control: Local start button, cable remote and radio remote are documented; no DMX is listed.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/look-solutions/tiny-s/fixture.json)
- [Blender model](../../../../assets/fixtures/look-solutions/tiny-s/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/look-solutions/tiny-s/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/look-solutions/tiny-s/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer L/W/H = 103/51/35 mm for single-component current Tiny S including battery and reservoir.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `fogger` profile with 33 visible meshes and 6,204 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/look-solutions/tiny-s/validation/detail.json) · [Front](../../../../assets/fixtures/look-solutions/tiny-s/previews/front.png) · [Side](../../../../assets/fixtures/look-solutions/tiny-s/previews/side.png) · [Rear](../../../../assets/fixtures/look-solutions/tiny-s/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/look-solutions/tiny-s/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/look-solutions/tiny-s/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
