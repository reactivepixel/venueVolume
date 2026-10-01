# Martin Professional (HARMAN) MAC Viper Performance

- Library state: `researched`
- Identity: model `MAC Viper Performance`; moving light / discharge framing profile
- Official source: [https://www.martin.com/en-US/products/mac-viper-performance](https://www.martin.com/en-US/products/mac-viper-performance) (accessed 2026-09-30)
- Reference envelope: 0.4720 m W × 0.7310 m H × 0.5660 m D
- Control: DMX, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/martin-professional-harman/mac-viper-performance/fixture.json)
- [Blender model](../../../../assets/fixtures/martin-professional-harman/mac-viper-performance/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/martin-professional-harman/mac-viper-performance/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/martin-professional-harman/mac-viper-performance/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Source values: width 472 mm (335 mm base), length 472 mm base / 566 mm head, height 731 mm with head straight up / 748 mm maximum. The product page and drawing list these distinct extents but do not define a single matching W×H×D box; depth uses the longer head length and height uses the head-straight-up pose. Treat this as an estimated envelope, not a fully documented pose.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.
- Source describes a vertical-head dimensional pose; modeled horizontal optical-axis pose fits that envelope. Verify pose-specific shape before placement/clearance use.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 18,644 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/martin-professional-harman/mac-viper-performance/validation/detail.json) · [Front](../../../../assets/fixtures/martin-professional-harman/mac-viper-performance/previews/front.png) · [Side](../../../../assets/fixtures/martin-professional-harman/mac-viper-performance/previews/side.png) · [Rear](../../../../assets/fixtures/martin-professional-harman/mac-viper-performance/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/martin-professional-harman/mac-viper-performance/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/martin-professional-harman/mac-viper-performance/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
