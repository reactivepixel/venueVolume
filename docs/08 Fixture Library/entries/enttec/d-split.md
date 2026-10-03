# ENTTEC D-SPLIT

- Library state: `ready_for_visualization`
- Identity: model `70574 / 70578 / 70579`; dmx_splitter / one-input, four-output optically isolated DMX splitter
- Official source: [https://www.enttec.com/es/product/dmx-isolated-splitter-din-rail/d-split-dmx-opto-splitter-isolator/](https://www.enttec.com/es/product/dmx-isolated-splitter-din-rail/d-split-dmx-opto-splitter-isolator/) (accessed 2026-09-30)
- Reference envelope: 0.1160 m W × 0.0520 m H × 0.0870 m D
- Control: USITT DMX512-1990 input to four isolated DMX512 outputs; no RDM compatibility; powered separately at 7-24 V DC; not an Ethernet node.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/enttec/d-split/fixture.json)
- [Blender model](../../../../assets/fixtures/enttec/d-split/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/enttec/d-split/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/enttec/d-split/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- 116 x 87 x 52 mm, manufacturer datasheet
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `splitter` profile with 14 visible meshes and 2,248 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/enttec/d-split/validation/detail.json) · [Front](../../../../assets/fixtures/enttec/d-split/previews/front.png) · [Side](../../../../assets/fixtures/enttec/d-split/previews/side.png) · [Rear](../../../../assets/fixtures/enttec/d-split/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/enttec/d-split/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/enttec/d-split/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
