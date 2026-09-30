# ADJ 7P HEX IP

- Library state: `ready_for_visualization`
- Identity: model `HEX700`; PAR / IP65 LED wash
- Official source: [https://www.adj.com/products/7p-hex-ip](https://www.adj.com/products/7p-hex-ip) (accessed 2026-09-30)
- Reference envelope: 0.1617 m W × 0.2325 m H × 0.2560 m D
- Control: DMX, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/7p-hex-ip/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/7p-hex-ip/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/7p-hex-ip/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/7p-hex-ip/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer specifies L x W x H; runtime X/Y/Z uses W/H/L.
- Moving components are separated but no runtime articulation joints are authored.
