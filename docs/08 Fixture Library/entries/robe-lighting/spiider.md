# ROBE Lighting Spiider

- Library state: `ready_for_visualization`
- Identity: model `Spiider`; Moving head / LED wash beam
- Official source: [https://www.robe.cz/spiider](https://www.robe.cz/spiider) (accessed 2026-09-30)
- Reference envelope: 0.3900 m W × 0.4770 m H × 0.2860 m D
- Control: DMX, RDM, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/robe-lighting/spiider/fixture.json)
- [Blender model](../../../../assets/fixtures/robe-lighting/spiider/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/robe-lighting/spiider/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/robe-lighting/spiider/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer specifies H x W x D with head vertical.
- Moving components are separated but no runtime articulation joints are authored.
