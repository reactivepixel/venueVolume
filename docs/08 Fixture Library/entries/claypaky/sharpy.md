# Claypaky Sharpy

- Library state: `researched`
- Identity: model `C61375`; Moving head / legacy beam
- Official source: [https://www.claypaky.it/products/sharpy-legacy/](https://www.claypaky.it/products/sharpy-legacy/) (accessed 2026-09-30)
- Reference envelope: 0.4050 m W × 0.4750 m H × 0.3300 m D
- Control: DMX, Art-Net, RDM, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/claypaky/sharpy/fixture.json)
- [Blender model](../../../../assets/fixtures/claypaky/sharpy/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/claypaky/sharpy/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/claypaky/sharpy/validation/usdz.json)

## Fidelity revision

- Revision 2 replaces the generic proxy with fixture-specific geometry derived from the stored official product image.
- Exact labels, small fasteners, connector geometry, internal mechanisms and photometry remain simplified.

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Base footprint and height are documented; base width/depth orientation follows the manufacturer drawing.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 3 uses a `moving_spot` profile with 85 visible meshes and 18,060 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/claypaky/sharpy/validation/detail.json) · [Front](../../../../assets/fixtures/claypaky/sharpy/previews/front.png) · [Side](../../../../assets/fixtures/claypaky/sharpy/previews/side.png) · [Rear](../../../../assets/fixtures/claypaky/sharpy/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/claypaky/sharpy/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/claypaky/sharpy/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
