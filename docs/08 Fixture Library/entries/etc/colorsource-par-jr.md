# ETC ColorSource PAR jr

- Library state: `ready_for_visualization`
- Identity: model `CSPARJR`; par / LED PAR
- Official source: [https://www.etcconnect.com/products/entertainment-fixtures/colorsource-par-jr/documentation.aspx](https://www.etcconnect.com/products/entertainment-fixtures/colorsource-par-jr/documentation.aspx) (accessed 2026-10-02)
- Reference envelope: 0.2130 m W × 0.2820 m H × 0.2510 m D
- Control: DMX512, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/etc/colorsource-par-jr/fixture.json)
- [Blender model](../../../../assets/fixtures/etc/colorsource-par-jr/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/etc/colorsource-par-jr/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/etc/colorsource-par-jr/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer table labels H282 × W213 × D251 mm, including yoke envelope.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `par` profile with 52 visible meshes and 18,444 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/etc/colorsource-par-jr/validation/detail.json) · [Front](../../../../assets/fixtures/etc/colorsource-par-jr/previews/front.png) · [Side](../../../../assets/fixtures/etc/colorsource-par-jr/previews/side.png) · [Rear](../../../../assets/fixtures/etc/colorsource-par-jr/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/etc/colorsource-par-jr/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/etc/colorsource-par-jr/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
