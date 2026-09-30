# Elation Professional Fuze SFX

- Library state: `ready_for_visualization`
- Identity: model `FUZ406`; Moving head / spot/effect
- Official source: [https://www.elationlighting.com/products/fuze-sfx](https://www.elationlighting.com/products/fuze-sfx) (accessed 2026-09-30)
- Reference envelope: 0.2330 m W × 0.5950 m H × 0.3620 m D
- Control: DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/elation-professional/fuze-sfx/fixture.json)
- [Blender model](../../../../assets/fixtures/elation-professional/fuze-sfx/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/elation-professional/fuze-sfx/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/elation-professional/fuze-sfx/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer lists length, width and height individually; runtime X/Y/Z uses width/height/length.
- Moving components are separated but no runtime articulation joints are authored.
