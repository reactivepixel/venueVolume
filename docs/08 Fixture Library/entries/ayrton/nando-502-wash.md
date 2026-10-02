# Ayrton Nando 502 Wash

- Library state: `researched`
- Identity: model `013420`; moving light / multi-source IP65 wash
- Official source: [https://www.ayrton.eu/produit/nando-502-wash/](https://www.ayrton.eu/produit/nando-502-wash/) (accessed 2026-10-02)
- Reference envelope: 0.3420 m W × 0.4670 m H × 0.2680 m D
- Control: DMX 512, DMX-RDM, ArtNet, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/ayrton/nando-502-wash/fixture.json)
- [Blender model](../../../../assets/fixtures/ayrton/nando-502-wash/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/ayrton/nando-502-wash/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/ayrton/nando-502-wash/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Current product page gives 342 x 467 x 268 mm (length x height x depth); older manual specifies 340 x 474 x 268 mm, so the conflicting revision dimensions are retained in evidence rather than blended.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/ayrton/nando-502-wash/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
