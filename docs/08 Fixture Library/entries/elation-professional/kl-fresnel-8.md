# Elation Professional KL Fresnel 8

- Library state: `ready_for_visualization`
- Identity: model `KLF023`; Fresnel / LED theatrical wash
- Official source: [https://www.elationlighting.com/products/kl-fresnel-8](https://www.elationlighting.com/products/kl-fresnel-8) (accessed 2026-09-30)
- Reference envelope: 0.3275 m W × 0.4560 m H × 0.6084 m D
- Control: DMX, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: fixture-specific editable Blender approximation, meter-scale USDZ, Y-up and -Z forward. Cylindrical lamp body, rear electronics enclosure, Fresnel rings, full yoke and four barn-door leaves.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/elation-professional/kl-fresnel-8/fixture.json)
- [Blender model](../../../../assets/fixtures/elation-professional/kl-fresnel-8/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/elation-professional/kl-fresnel-8/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/elation-professional/kl-fresnel-8/validation/usdz.json)

## Fidelity revision

- Revision 2 replaces the generic proxy with fixture-specific geometry derived from the stored official product image.
- Exact labels, small fasteners, connector geometry, internal mechanisms and photometry remain simplified.

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer lists length, width and height individually; runtime X/Y/Z uses width/height/length.
- Moving components are separated but no runtime articulation joints are authored.
