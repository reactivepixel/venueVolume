# ACME LIGHTNING

- Library state: `ready_for_visualization`
- Identity: model `STROBE 6 IP`; strobe / pixel strobe / wash / beam array
- Official source: [https://en.acmelighting.com/item/LIGHTNING](https://en.acmelighting.com/item/LIGHTNING) (accessed 2026-10-02)
- Reference envelope: 0.4830 m W × 0.2240 m H × 0.2120 m D
- Control: DMX512, RDM, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/acme/lightning/fixture.json)
- [Blender model](../../../../assets/fixtures/acme/lightning/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/acme/lightning/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/acme/lightning/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer physical specs explicitly label width 483 mm, depth 212 mm, height 224 mm.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `strobe` profile with 341 visible meshes and 22,364 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/acme/lightning/validation/detail.json) · [Front](../../../../assets/fixtures/acme/lightning/previews/front.png) · [Side](../../../../assets/fixtures/acme/lightning/previews/side.png) · [Rear](../../../../assets/fixtures/acme/lightning/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/acme/lightning/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/acme/lightning/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
