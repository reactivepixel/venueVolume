# ADJ Hydro Beam X1

- Library state: `ready_for_visualization`
- Identity: model `HYD100`; Moving head / IP65 beam
- Official source: [https://www.adj.com/products/hydro-beam-x1](https://www.adj.com/products/hydro-beam-x1) (accessed 2026-09-30)
- Reference envelope: 0.2100 m W × 0.4300 m H × 0.3360 m D
- Control: DMX512, RDM, W-DMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/hydro-beam-x1/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/hydro-beam-x1/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/hydro-beam-x1/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/hydro-beam-x1/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer specifies L x W x H; runtime X/Y/Z uses W/H/L.
- Moving components are separated but no runtime articulation joints are authored.
