# Claypaky Sharpy Plus Aqua

- Library state: `ready_for_visualization`
- Identity: model `CD3002`; Moving head / IP66 hybrid beam spot
- Official source: [https://www.claypaky.it/products/sharpy-plus-aqua/](https://www.claypaky.it/products/sharpy-plus-aqua/) (accessed 2026-09-30)
- Reference envelope: 0.4200 m W × 0.7310 m H × 0.3360 m D
- Control: DMX, Art-Net, RDM, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/claypaky/sharpy-plus-aqua/fixture.json)
- [Blender model](../../../../assets/fixtures/claypaky/sharpy-plus-aqua/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/claypaky/sharpy-plus-aqua/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/claypaky/sharpy-plus-aqua/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer specifies L x W x H; runtime X/Y/Z uses W/H/L.
- Moving components are separated but no runtime articulation joints are authored.
