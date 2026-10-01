# ADJ Dynasty Scan DMX

- Library state: `researched`
- Identity: model `DYNASTY SCAN`; scanner / 150 W discharge moving-mirror scanner
- Official source: [https://www.adj.com/products/dynasty-scan-dmx](https://www.adj.com/products/dynasty-scan-dmx) (accessed 2026-09-30)
- Reference envelope: 0.1850 m W × 0.1950 m H × 0.4600 m D
- Control: DMX 6-channel or onboard sound-active programs
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/dynasty-scan-dmx/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/dynasty-scan-dmx/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/dynasty-scan-dmx/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/dynasty-scan-dmx/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Manufacturer LxWxH mapped to a table-mounted scanner with the front optical aperture facing forward along depth. Neutral-pose axis assignment is image-inferred, not established by a labelled drawing.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `scanner` profile with 16 visible meshes and 9,452 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/adj/dynasty-scan-dmx/validation/detail.json) · [Front](../../../../assets/fixtures/adj/dynasty-scan-dmx/previews/front.png) · [Side](../../../../assets/fixtures/adj/dynasty-scan-dmx/previews/side.png) · [Rear](../../../../assets/fixtures/adj/dynasty-scan-dmx/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/adj/dynasty-scan-dmx/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/adj/dynasty-scan-dmx/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
