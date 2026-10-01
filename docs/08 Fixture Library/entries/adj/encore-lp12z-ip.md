# ADJ Encore LP12Z IP

- Library state: `researched`
- Identity: model `ENC395`; par / IP65 RGBL motorized-zoom wash
- Official source: [https://www.adj.com/products/encore-lp12z-ip](https://www.adj.com/products/encore-lp12z-ip) (accessed 2026-09-30)
- Reference envelope: 0.3160 m W × 0.3460 m H × 0.3710 m D
- Control: DMX, RDM, Aria X2; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/encore-lp12z-ip/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/encore-lp12z-ip/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/encore-lp12z-ip/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/encore-lp12z-ip/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- ADJ's page conflicts: overview says 222 x 316 x 367 mm while the detailed dimensions list says 371 x 316 x 346 mm. This row retains the detailed list; verify against official CAD before scaling.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `par` profile with 79 visible meshes and 27,828 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/adj/encore-lp12z-ip/validation/detail.json) · [Front](../../../../assets/fixtures/adj/encore-lp12z-ip/previews/front.png) · [Side](../../../../assets/fixtures/adj/encore-lp12z-ip/previews/side.png) · [Rear](../../../../assets/fixtures/adj/encore-lp12z-ip/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/adj/encore-lp12z-ip/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/encore-lp12z-ip/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
