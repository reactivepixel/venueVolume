# GLP JDC1

- Library state: `ready_for_visualization`
- Identity: model `JDC1`; Strobe / blinder / hybrid strobe
- Official source: [https://glp.de/en/products/entertainment-lighting/strobes/jdc1-en?ic=1](https://glp.de/en/products/entertainment-lighting/strobes/jdc1-en?ic=1) (accessed 2026-09-30)
- Reference envelope: 0.3900 m W × 0.2510 m H × 0.1500 m D
- Control: DMX512-A, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/glp/jdc1/fixture.json)
- [Blender model](../../../../assets/fixtures/glp/jdc1/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/glp/jdc1/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/glp/jdc1/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer specifies H x W x D.
- Moving components are separated but no runtime articulation joints are authored.
