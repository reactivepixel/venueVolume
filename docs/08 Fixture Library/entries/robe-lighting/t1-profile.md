# ROBE Lighting T1 Profile

- Library state: `ready_for_visualization`
- Identity: model `T1 Profile`; Moving head / profile
- Official source: [https://www.robe.cz/t1-profile](https://www.robe.cz/t1-profile) (accessed 2026-09-30)
- Reference envelope: 0.4910 m W × 0.5420 m H × 0.3440 m D
- Control: DMX, RDM, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/robe-lighting/t1-profile/fixture.json)
- [Blender model](../../../../assets/fixtures/robe-lighting/t1-profile/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/robe-lighting/t1-profile/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/robe-lighting/t1-profile/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer specifies H x W x D with head vertical.
- Moving components are separated but no runtime articulation joints are authored.
