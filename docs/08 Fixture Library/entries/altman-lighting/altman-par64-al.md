# Altman Lighting Altman PAR64-AL

- Library state: `researched`
- Identity: model `PAR64-AL`; par_can / Traditional aluminum PAR64 tungsten can, external dimmer controlled
- Official source: [https://www.altmanlighting.com/wp-content/uploads/2019/05/PAR64ALSpecification_disc.pdf](https://www.altmanlighting.com/wp-content/uploads/2019/05/PAR64ALSpecification_disc.pdf) (accessed 2026-09-30)
- Reference envelope: 0.2790 m W × 0.3900 m H × 0.4060 m D
- Control: Passive tungsten fixture; lamp fed by external mains dimmer
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/altman-lighting/altman-par64-al/fixture.json)
- [Blender model](../../../../assets/fixtures/altman-lighting/altman-par64-al/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/altman-lighting/altman-par64-al/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/altman-lighting/altman-par64-al/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Manufacturer dimension drawing, assembled fixture outline; excludes packaging.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.
- No official product image URL was present in the research CSV.

## Detailed model revision

Revision 2 uses a `par_can` profile with 28 visible meshes and 3,252 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/altman-lighting/altman-par64-al/validation/detail.json) · [Front](../../../../assets/fixtures/altman-lighting/altman-par64-al/previews/front.png) · [Side](../../../../assets/fixtures/altman-lighting/altman-par64-al/previews/side.png) · [Rear](../../../../assets/fixtures/altman-lighting/altman-par64-al/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/altman-lighting/altman-par64-al/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/altman-lighting/altman-par64-al/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
