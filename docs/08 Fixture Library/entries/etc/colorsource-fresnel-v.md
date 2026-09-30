# ETC ColorSource Fresnel V

- Library state: `ready_for_visualization`
- Identity: model `ColorSource Fresnel V`; Fresnel / LED Fresnel
- Official source: [https://www.etcconnect.com/Products/Entertainment-Fixtures/ColorSource-Fresnel-V/Documentation.aspx](https://www.etcconnect.com/Products/Entertainment-Fixtures/ColorSource-Fresnel-V/Documentation.aspx) (accessed 2026-09-30)
- Reference envelope: 0.3210 m W × 0.3390 m H × 0.3110 m D
- Control: DMX, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/etc/colorsource-fresnel-v/fixture.json)
- [Blender model](../../../../assets/fixtures/etc/colorsource-fresnel-v/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/etc/colorsource-fresnel-v/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/etc/colorsource-fresnel-v/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer specifies H x W x D.
- Moving components are separated but no runtime articulation joints are authored.
