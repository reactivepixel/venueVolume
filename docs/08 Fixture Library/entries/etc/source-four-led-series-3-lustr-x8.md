# ETC Source Four LED Series 3 Lustr X8

- Library state: `researched`
- Identity: model `S4LEDS3LS-0`; Profile / ellipsoidal LED
- Official source: [https://www.etcconnect.com/Products/Entertainment-Fixtures/Source-Four-LED-Series-3/Documentation.aspx](https://www.etcconnect.com/Products/Entertainment-Fixtures/Source-Four-LED-Series-3/Documentation.aspx) (accessed 2026-09-30)
- Reference envelope: 0.3400 m W × 0.3400 m H × 0.7210 m D
- Control: DMX512, RDM, wireless DMX/RDM (Multiverse); exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/etc/source-four-led-series-3-lustr-x8/fixture.json)
- [Blender model](../../../../assets/fixtures/etc/source-four-led-series-3-lustr-x8/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/etc/source-four-led-series-3-lustr-x8/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/etc/source-four-led-series-3-lustr-x8/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Maximum lens-tube envelope is documented; long axis is assigned to runtime depth.
- Moving components are separated but no runtime articulation joints are authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.
