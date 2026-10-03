# Astera Titan Tube

- Library state: `researched`
- Identity: model `FP1-BTB`; linear fixture / wireless RGBMintAmber pixel tube
- Official source: [https://astera-led.com/wp-content/uploads/FP1_Titan-Tube_Datasheet_V3.pdf](https://astera-led.com/wp-content/uploads/FP1_Titan-Tube_Datasheet_V3.pdf) (accessed 2026-10-02)
- Reference envelope: 1.0350 m W × 0.0430 m H × 0.0430 m D
- Control: DMX512 (via Astera interface), CRMX, UHF, Bluetooth, Wi-Fi; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/astera/titan-tube/fixture.json)
- [Blender model](../../../../assets/fixtures/astera/titan-tube/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/astera/titan-tube/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/astera/titan-tube/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer datasheet specifies 1035 mm overall length × Ø43 mm; modeled horizontally as width × circular height/depth.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/astera/titan-tube/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
