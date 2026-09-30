# Elation Professional SixBar 1000

- Library state: `ready_for_visualization`
- Identity: model `SIX086`; Batten / LED pixel bar
- Official source: [https://www.elationlighting.com/products/sixbar-1000](https://www.elationlighting.com/products/sixbar-1000) (accessed 2026-09-30)
- Reference envelope: 0.9000 m W × 0.1550 m H × 0.2064 m D
- Control: DMX, Art-Net, Kling-Net, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/elation-professional/sixbar-1000/fixture.json)
- [Blender model](../../../../assets/fixtures/elation-professional/sixbar-1000/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/elation-professional/sixbar-1000/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/elation-professional/sixbar-1000/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer lists bar length, width and height; runtime width follows bar length.
- Moving components are separated but no runtime articulation joints are authored.
