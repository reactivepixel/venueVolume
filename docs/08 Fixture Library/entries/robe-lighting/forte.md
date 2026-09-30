# ROBE Lighting FORTE

- Library state: `ready_for_visualization`
- Identity: model `FORTE`; Moving head / profile
- Official source: [https://www.robe.cz/forte](https://www.robe.cz/forte) (accessed 2026-09-30)
- Reference envelope: 0.4835 m W × 0.6355 m H × 0.6245 m D
- Control: DMX, RDM, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: fixture-specific editable Blender approximation, meter-scale USDZ, Y-up and -Z forward. Vented rounded base, display, angled heavy yoke, long optical barrel, metal bezel and cooling detail.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/robe-lighting/forte/fixture.json)
- [Blender model](../../../../assets/fixtures/robe-lighting/forte/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/robe-lighting/forte/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/robe-lighting/forte/validation/usdz.json)

## Fidelity revision

- Revision 2 replaces the generic proxy with fixture-specific geometry derived from the stored official product image.
- Exact labels, small fasteners, connector geometry, internal mechanisms and photometry remain simplified.

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer specifies H x W x D for the horizontal-head pose; upright sweep height is retained separately.
- Moving components are separated but no runtime articulation joints are authored.
