# ETC ColorSource Spot V

- Library state: `researched`
- Identity: model `ColorSource Spot V`; Profile / LED spot
- Official source: [https://www.etcconnect.com/Products/Entertainment-Fixtures/ColorSource-Spot-V/Documentation.aspx](https://www.etcconnect.com/Products/Entertainment-Fixtures/ColorSource-Spot-V/Documentation.aspx) (accessed 2026-09-30)
- Reference envelope: 0.3390 m W × 0.5930 m H × 0.6720 m D
- Control: DMX, RDM, wireless DMX/RDM (Multiverse); exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/etc/colorsource-spot-v/fixture.json)
- [Blender model](../../../../assets/fixtures/etc/colorsource-spot-v/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/etc/colorsource-spot-v/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/etc/colorsource-spot-v/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Maximum barrel/lens envelope is documented; H/W/depth assignment follows the manufacturer drawing orientation.
- Moving components are separated but no runtime articulation joints are authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.
