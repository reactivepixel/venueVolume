# Claypaky Volero Cube

- Library state: `researched`
- Identity: model `CL3031`; moving light / IP66 beam / wash / strobe
- Official source: [https://www.claypaky.it/products/volero-cube/](https://www.claypaky.it/products/volero-cube/) (accessed 2026-10-02)
- Reference envelope: 0.2450 m W × 0.4760 m H × 0.3380 m D
- Control: DMX, Art-Net, RDM, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/claypaky/volero-cube/fixture.json)
- [Blender model](../../../../assets/fixtures/claypaky/volero-cube/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/claypaky/volero-cube/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/claypaky/volero-cube/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer specifies 245 x 338 mm base and 476 mm height with vertical head. Width/depth mapping of the two base axes is assigned from page views and is an estimate; retain original undirected spans.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 74 visible meshes and 12,584 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/claypaky/volero-cube/validation/detail.json) · [Front](../../../../assets/fixtures/claypaky/volero-cube/previews/front.png) · [Side](../../../../assets/fixtures/claypaky/volero-cube/previews/side.png) · [Rear](../../../../assets/fixtures/claypaky/volero-cube/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/claypaky/volero-cube/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/claypaky/volero-cube/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
