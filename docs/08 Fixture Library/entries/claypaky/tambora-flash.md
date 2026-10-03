# Claypaky Tambora Flash

- Library state: `ready_for_visualization`
- Identity: model `CL2020`; hybrid LED effect / strobe / wash / blinder
- Official source: [https://www.claypaky.it/products/tambora-flash/](https://www.claypaky.it/products/tambora-flash/) (accessed 2026-09-30)
- Reference envelope: 0.4970 m W × 0.1860 m H × 0.1800 m D
- Control: DMX512, RDM, Art-Net, sACN, WebServer, Kling-Net; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/claypaky/tambora-flash/fixture.json)
- [Blender model](../../../../assets/fixtures/claypaky/tambora-flash/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/claypaky/tambora-flash/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/claypaky/tambora-flash/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Current Claypaky product page gives 497 x 180 x 186 mm without handles; order interpreted as length, width, height, with long dimension across batten width. A February 2024 leaflet reports a conflicting length of 533 mm; the current page value is retained and conflict recorded.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 2 uses a `strobe` profile with 48 visible meshes and 11,360 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/claypaky/tambora-flash/validation/detail.json) · [Front](../../../../assets/fixtures/claypaky/tambora-flash/previews/front.png) · [Side](../../../../assets/fixtures/claypaky/tambora-flash/previews/side.png) · [Rear](../../../../assets/fixtures/claypaky/tambora-flash/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/claypaky/tambora-flash/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/claypaky/tambora-flash/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
