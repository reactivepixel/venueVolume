# ETC fos/4 Fresnel

- Library state: `researched`
- Identity: model `fos/4 Fresnel`; Fresnel / LED Fresnel
- Official source: [https://www.etcconnect.com/Products/Entertainment-Fixtures/fos/4-Fresnel/Documentation.aspx](https://www.etcconnect.com/Products/Entertainment-Fixtures/fos/4-Fresnel/Documentation.aspx) (accessed 2026-09-30)
- Reference envelope: 0.3130 m W × 0.4350 m H × 0.5050 m D
- Control: DMX, RDM, wireless DMX/RDM (Multiverse); exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/etc/fos-4-fresnel/fixture.json)
- [Blender model](../../../../assets/fixtures/etc/fos-4-fresnel/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/etc/fos-4-fresnel/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/etc/fos-4-fresnel/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Zoom range envelope is documented; the extended depth is used for a conservative outer bound.
- Moving components are separated but no runtime articulation joints are authored.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.
- No official product image URL was present in the research CSV.
