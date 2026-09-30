# CHAUVET Professional COLORado Solo Batten

- Library state: `researched`
- Identity: model `COLORADOSOLOBATTEN`; Batten / IP-rated pixel batten
- Official source: [https://chauvetprofessional.com/product/colorado-solo-batten/](https://chauvetprofessional.com/product/colorado-solo-batten/) (accessed 2026-09-30)
- Reference envelope: 1.0125 m W × 0.2498 m H × 0.2300 m D
- Control: DMX, RDM, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: fixture-specific editable Blender approximation, meter-scale USDZ, Y-up and -Z forward. Ribbed extrusion, continuous twelve-segment optic, electronics pod and mounting feet.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chauvet-professional/colorado-solo-batten/fixture.json)
- [Blender model](../../../../assets/fixtures/chauvet-professional/colorado-solo-batten/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chauvet-professional/colorado-solo-batten/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chauvet-professional/colorado-solo-batten/validation/usdz.json)

## Fidelity revision

- Revision 2 replaces the generic proxy with fixture-specific geometry derived from the stored official product image.
- Exact labels, small fasteners, connector geometry, internal mechanisms and photometry remain simplified.

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Overall dimensions are documented; bar-length/height/depth axis assignment is inferred from product class and imagery.
- Moving components are separated but no runtime articulation joints are authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.
