# Elation Professional KL Fresnel 8

- Library state: `ready_for_visualization`
- Identity: model `KLF023`; Fresnel / LED theatrical wash
- Official source: [https://www.elationlighting.com/products/kl-fresnel-8](https://www.elationlighting.com/products/kl-fresnel-8) (accessed 2026-09-30)
- Reference envelope: 0.3275 m W × 0.4560 m H × 0.6084 m D
- Control: DMX, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/elation-professional/kl-fresnel-8/fixture.json)
- [Blender model](../../../../assets/fixtures/elation-professional/kl-fresnel-8/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/elation-professional/kl-fresnel-8/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/elation-professional/kl-fresnel-8/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer lists length, width and height individually; runtime X/Y/Z uses width/height/length.
- Moving components are separated but no runtime articulation joints are authored.
