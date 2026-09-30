# ADJ STRYKER WASH

- Library state: `ready_for_visualization`
- Identity: model `STR100`; Moving head / wash
- Official source: [https://www.adj.com/products/stryker-wash](https://www.adj.com/products/stryker-wash) (accessed 2026-09-30)
- Reference envelope: 0.3240 m W × 0.3990 m H × 0.2220 m D
- Control: DMX-512; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/stryker-wash/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/stryker-wash/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/stryker-wash/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/stryker-wash/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer specifies L x W x H; runtime X/Y/Z uses W/H/L.
- Moving components are separated but no runtime articulation joints are authored.
