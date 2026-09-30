# GLP impression X5

- Library state: `ready_for_visualization`
- Identity: model `7795`; Moving head / LED wash
- Official source: [https://glp.de/en/products/entertainment-lighting/moving-lights/impression-x5-en](https://glp.de/en/products/entertainment-lighting/moving-lights/impression-x5-en) (accessed 2026-09-30)
- Reference envelope: 0.4150 m W × 0.4340 m H × 0.2900 m D
- Control: DMX, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/glp/impression-x5/fixture.json)
- [Blender model](../../../../assets/fixtures/glp/impression-x5/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/glp/impression-x5/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/glp/impression-x5/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer specifies H x W x D; maximum documented height is used.
- Moving components are separated but no runtime articulation joints are authored.
