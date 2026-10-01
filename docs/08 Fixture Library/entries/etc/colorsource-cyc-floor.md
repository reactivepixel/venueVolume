# ETC ColorSource CYC Floor

- Library state: `ready_for_visualization`
- Identity: model `CSCYC`; cyc / Dedicated asymmetric five-color LED cyclorama luminaire, floor form
- Official source: [https://www.etcconnect.com/products/entertainment-fixtures/colorsource-cyc/tech-specs.aspx](https://www.etcconnect.com/products/entertainment-fixtures/colorsource-cyc/tech-specs.aspx) (accessed 2026-09-30)
- Reference envelope: 0.2660 m W × 0.1990 m H × 0.2210 m D
- Control: DMX/RDM and local presets
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/etc/colorsource-cyc-floor/fixture.json)
- [Blender model](../../../../assets/fixtures/etc/colorsource-cyc-floor/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/etc/colorsource-cyc-floor/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/etc/colorsource-cyc-floor/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- ETC floor form dimensions, not hang form.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `cyc` profile with 24 visible meshes and 4,608 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/etc/colorsource-cyc-floor/validation/detail.json) · [Front](../../../../assets/fixtures/etc/colorsource-cyc-floor/previews/front.png) · [Side](../../../../assets/fixtures/etc/colorsource-cyc-floor/previews/side.png) · [Rear](../../../../assets/fixtures/etc/colorsource-cyc-floor/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/etc/colorsource-cyc-floor/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/etc/colorsource-cyc-floor/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
