# Elation Professional DARTZ 360

- Library state: `ready_for_visualization`
- Identity: model `DAR880`; Moving head / beam
- Official source: [https://www.elationlighting.com/products/dartz-360](https://www.elationlighting.com/products/dartz-360) (accessed 2026-09-30)
- Reference envelope: 0.1960 m W × 0.4547 m H × 0.2842 m D
- Control: DMX, RDM, Kling-Net, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/elation-professional/dartz-360/fixture.json)
- [Blender model](../../../../assets/fixtures/elation-professional/dartz-360/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/elation-professional/dartz-360/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/elation-professional/dartz-360/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer lists length, width and height individually; runtime X/Y/Z uses width/height/length.
- Moving components are separated but no runtime articulation joints are authored.
