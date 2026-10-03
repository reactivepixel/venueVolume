# ETC ColorSource Spot jr

- Library state: `ready_for_visualization`
- Identity: model `CSSPOTJR2550`; fixed light / LED profile / ellipsoidal
- Official source: [https://www.etcconnect.com/products/entertainment-fixtures/colorsource-spot-jr/documentation.aspx](https://www.etcconnect.com/products/entertainment-fixtures/colorsource-spot-jr/documentation.aspx) (accessed 2026-10-02)
- Reference envelope: 0.2580 m W × 0.3310 m H × 0.4600 m D
- Control: DMX512, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/etc/colorsource-spot-jr/fixture.json)
- [Blender model](../../../../assets/fixtures/etc/colorsource-spot-jr/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/etc/colorsource-spot-jr/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/etc/colorsource-spot-jr/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer physical drawing labels width 258 mm, height 331 mm and depth 460 mm for the assembled fixture.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `profile` profile with 46 visible meshes and 16,720 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/etc/colorsource-spot-jr/validation/detail.json) · [Front](../../../../assets/fixtures/etc/colorsource-spot-jr/previews/front.png) · [Side](../../../../assets/fixtures/etc/colorsource-spot-jr/previews/side.png) · [Rear](../../../../assets/fixtures/etc/colorsource-spot-jr/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/etc/colorsource-spot-jr/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/etc/colorsource-spot-jr/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
