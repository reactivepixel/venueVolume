# Astera NYX Bulb

- Library state: `ready_for_visualization`
- Identity: model `FP5-E27`; practical / Color-tunable RGBMA E27/E26 LED practical bulb with wireless CRMX
- Official source: [https://nyx-for-filmmakers.astera-led.com/](https://nyx-for-filmmakers.astera-led.com/) (accessed 2026-09-30)
- Reference envelope: 0.0700 m W × 0.1300 m H × 0.0700 m D
- Control: E27 mains socket or external 5–18 V DC input; wireless CRMX DMX, UHF and Bluetooth
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/astera/nyx-bulb/fixture.json)
- [Blender model](../../../../assets/fixtures/astera/nyx-bulb/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/astera/nyx-bulb/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/astera/nyx-bulb/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Astera-authorized distributor supplies the bulb-only Ø70 x 130 mm and 0.24 kg dimensions.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `practical` profile with 11 visible meshes and 7,520 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/astera/nyx-bulb/validation/detail.json) · [Front](../../../../assets/fixtures/astera/nyx-bulb/previews/front.png) · [Side](../../../../assets/fixtures/astera/nyx-bulb/previews/side.png) · [Rear](../../../../assets/fixtures/astera/nyx-bulb/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/astera/nyx-bulb/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/astera/nyx-bulb/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
