# CHAUVET Professional COLORado Solo Batten

- Library state: `researched`
- Identity: model `COLORADOSOLOBATTEN`; Batten / IP-rated pixel batten
- Official source: [https://chauvetprofessional.com/product/colorado-solo-batten/](https://chauvetprofessional.com/product/colorado-solo-batten/) (accessed 2026-09-30)
- Reference envelope: 1.0125 m W × 0.2498 m H × 0.2300 m D
- Control: DMX, RDM, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chauvet-professional/colorado-solo-batten/fixture.json)
- [Blender model](../../../../assets/fixtures/chauvet-professional/colorado-solo-batten/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chauvet-professional/colorado-solo-batten/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chauvet-professional/colorado-solo-batten/validation/usdz.json)

## Fidelity revision

- Revision 2 replaces the generic proxy with fixture-specific geometry derived from the stored official product image.
- Exact labels, small fasteners, connector geometry, internal mechanisms and photometry remain simplified.

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Overall dimensions are documented; bar-length/height/depth axis assignment is inferred from product class and imagery.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 3 uses a `batten` profile with 50 visible meshes and 9,416 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/chauvet-professional/colorado-solo-batten/validation/detail.json) · [Front](../../../../assets/fixtures/chauvet-professional/colorado-solo-batten/previews/front.png) · [Side](../../../../assets/fixtures/chauvet-professional/colorado-solo-batten/previews/side.png) · [Rear](../../../../assets/fixtures/chauvet-professional/colorado-solo-batten/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/chauvet-professional/colorado-solo-batten/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chauvet-professional/colorado-solo-batten/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
