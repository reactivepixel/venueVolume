# ADJ LED Bar

- Library state: `ready_for_visualization`
- Identity: model `LED BAR`; Batten / LED wash bar
- Official source: [https://www.adj.com/products/led-bar](https://www.adj.com/products/led-bar) (accessed 2026-09-30)
- Reference envelope: 0.5000 m W × 0.1320 m H × 0.0900 m D
- Control: DMX-512; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/led-bar/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/led-bar/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/led-bar/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/led-bar/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer specifies bar L x W x H; runtime width follows bar length.
- Moving components are separated but no runtime articulation joints are authored.
