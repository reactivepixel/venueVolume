# ETC ColorSource Spot V

- Library state: `researched`
- Identity: model `ColorSource Spot V`; Profile / LED spot
- Official source: [https://www.etcconnect.com/Products/Entertainment-Fixtures/ColorSource-Spot-V/Documentation.aspx](https://www.etcconnect.com/Products/Entertainment-Fixtures/ColorSource-Spot-V/Documentation.aspx) (accessed 2026-09-30)
- Reference envelope: 0.3390 m W × 0.5930 m H × 0.6720 m D
- Control: DMX, RDM, wireless DMX/RDM (Multiverse); exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/etc/colorsource-spot-v/fixture.json)
- [Blender model](../../../../assets/fixtures/etc/colorsource-spot-v/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/etc/colorsource-spot-v/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/etc/colorsource-spot-v/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Maximum barrel/lens envelope is documented; H/W/depth assignment follows the manufacturer drawing orientation.
- Moving parts have editable pivots; runtime physics joints are not authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 4 uses a `profile` profile with 47 visible meshes and 16,908 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/etc/colorsource-spot-v/validation/detail.json) · [Front](../../../../assets/fixtures/etc/colorsource-spot-v/previews/front.png) · [Side](../../../../assets/fixtures/etc/colorsource-spot-v/previews/side.png) · [Rear](../../../../assets/fixtures/etc/colorsource-spot-v/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/etc/colorsource-spot-v/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/etc/colorsource-spot-v/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
