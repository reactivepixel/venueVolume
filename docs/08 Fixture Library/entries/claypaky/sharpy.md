# Claypaky Sharpy

- Library state: `researched`
- Identity: model `C61375`; Moving head / legacy beam
- Official source: [https://www.claypaky.it/products/sharpy-legacy/](https://www.claypaky.it/products/sharpy-legacy/) (accessed 2026-09-30)
- Reference envelope: 0.4050 m W × 0.4750 m H × 0.3300 m D
- Control: DMX, Art-Net, RDM, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/claypaky/sharpy/fixture.json)
- [Blender model](../../../../assets/fixtures/claypaky/sharpy/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/claypaky/sharpy/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/claypaky/sharpy/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Base footprint and height are documented; base width/depth orientation follows the manufacturer drawing.
- Moving components are separated but no runtime articulation joints are authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.
