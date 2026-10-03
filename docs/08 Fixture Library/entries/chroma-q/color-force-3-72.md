# Chroma-Q Color Force 3 72

- Library state: `researched`
- Identity: model `CQ1530-7200`; LED wash / cyc / wash batten
- Official source: [https://chroma-q.com/products/color-force-3-72](https://chroma-q.com/products/color-force-3-72) (accessed 2026-10-02)
- Reference envelope: 1.7850 m W × 0.2150 m H × 0.1800 m D
- Control: DMX512-A, Art-Net, sACN, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chroma-q/color-force-3-72/fixture.json)
- [Blender model](../../../../assets/fixtures/chroma-q/color-force-3-72/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chroma-q/color-force-3-72/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chroma-q/color-force-3-72/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer mechanical specifications; optical-forward neutral pose and detail proportions are image-informed estimates.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `batten` profile with 110 visible meshes and 14,552 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/chroma-q/color-force-3-72/validation/detail.json) · [Front](../../../../assets/fixtures/chroma-q/color-force-3-72/previews/front.png) · [Side](../../../../assets/fixtures/chroma-q/color-force-3-72/previews/side.png) · [Rear](../../../../assets/fixtures/chroma-q/color-force-3-72/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/chroma-q/color-force-3-72/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chroma-q/color-force-3-72/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
