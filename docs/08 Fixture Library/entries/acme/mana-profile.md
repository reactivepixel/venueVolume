# ACME MANA PROFILE

- Library state: `researched`
- Identity: model `XA 600 BSWF IP`; moving light / LED framing profile / spot
- Official source: [https://en.acmelighting.com/item/MANA-PROFILE](https://en.acmelighting.com/item/MANA-PROFILE) (accessed 2026-10-02)
- Reference envelope: 0.3800 m W × 0.6580 m H × 0.2840 m D
- Control: DMX512, RDM, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/acme/mana-profile/fixture.json)
- [Blender model](../../../../assets/fixtures/acme/mana-profile/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/acme/mana-profile/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/acme/mana-profile/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer 2026 leaflet physical information lists fixture dimensions 380 × 284 × 658 mm; mapped to W × D × H, corroborated by its dimension illustration.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/acme/mana-profile/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
