# GLP impression X5 IP Maxx

- Library state: `researched`
- Identity: model `7796`; moving light / IP65 LED wash
- Official source: [https://glp.de/en/products/entertainment-lighting/moving-lights/impression-x5-ip-maxx-en](https://glp.de/en/products/entertainment-lighting/moving-lights/impression-x5-ip-maxx-en) (accessed 2026-09-30)
- Reference envelope: 0.4830 m W × 0.6400 m H × 0.3580 m D
- Control: DMX, RDM, Art-Net, sACN, CRMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/glp/impression-x5-ip-maxx/fixture.json)
- [Blender model](../../../../assets/fixtures/glp/impression-x5-ip-maxx/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/glp/impression-x5-ip-maxx/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/glp/impression-x5-ip-maxx/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- GLP product data and safety manual; height includes rubber feet, width across yoke, head vertical. Datasheet depth is 348 mm while current product page gives 358 mm; conservative current product-page value is retained.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Source describes a vertical-head dimensional pose; modeled horizontal optical-axis pose fits that envelope. Verify pose-specific shape before placement/clearance use.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 139 visible meshes and 49,776 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/glp/impression-x5-ip-maxx/validation/detail.json) · [Front](../../../../assets/fixtures/glp/impression-x5-ip-maxx/previews/front.png) · [Side](../../../../assets/fixtures/glp/impression-x5-ip-maxx/previews/side.png) · [Rear](../../../../assets/fixtures/glp/impression-x5-ip-maxx/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/glp/impression-x5-ip-maxx/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/glp/impression-x5-ip-maxx/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
