# ROBE Lighting Pointe

- Library state: `ready_for_visualization`
- Identity: model `Pointe`; Moving head / legacy hybrid
- Official source: [https://www.robe.cz/pointe](https://www.robe.cz/pointe) (accessed 2026-09-30)
- Reference envelope: 0.4000 m W × 0.5300 m H × 0.2800 m D
- Control: DMX, RDM, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/robe-lighting/pointe/fixture.json)
- [Blender model](../../../../assets/fixtures/robe-lighting/pointe/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/robe-lighting/pointe/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/robe-lighting/pointe/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer specifies H x W x D.
- Moving components are separated but no runtime articulation joints are authored.
