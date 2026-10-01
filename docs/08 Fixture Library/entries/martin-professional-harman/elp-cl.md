# Martin Professional (HARMAN) ELP CL

- Library state: `researched`
- Identity: model `ELP CL`; Profile / static LED ellipsoidal
- Official source: [https://www.martin.com/en-US/products/elp-cl](https://www.martin.com/en-US/products/elp-cl) (accessed 2026-09-30)
- Reference envelope: 0.2590 m W × 0.4270 m H × 0.6480 m D
- Control: DMX, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/martin-professional-harman/elp-cl/fixture.json)
- [Blender model](../../../../assets/fixtures/martin-professional-harman/elp-cl/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/martin-professional-harman/elp-cl/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/martin-professional-harman/elp-cl/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Bracketed envelope is documented; long housing axis is assigned to runtime depth.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `profile` profile with 47 visible meshes and 16,908 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/martin-professional-harman/elp-cl/validation/detail.json) · [Front](../../../../assets/fixtures/martin-professional-harman/elp-cl/previews/front.png) · [Side](../../../../assets/fixtures/martin-professional-harman/elp-cl/previews/side.png) · [Rear](../../../../assets/fixtures/martin-professional-harman/elp-cl/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/martin-professional-harman/elp-cl/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/martin-professional-harman/elp-cl/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
