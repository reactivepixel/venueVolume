# ADJ Jolt Bar FX

- Library state: `ready_for_visualization`
- Identity: model `JOLT-BAR-FX`; Batten / LED strobe/blinder bar
- Official source: [https://www.adj.com/products/jolt-bar-fx](https://www.adj.com/products/jolt-bar-fx) (accessed 2026-09-30)
- Reference envelope: 1.0000 m W × 0.1230 m H × 0.1070 m D
- Control: DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/jolt-bar-fx/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/jolt-bar-fx/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/jolt-bar-fx/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/jolt-bar-fx/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer specifies bar L x W x H; runtime width follows bar length.
- Moving components are separated but no runtime articulation joints are authored.
