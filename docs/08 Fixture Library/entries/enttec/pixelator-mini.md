# ENTTEC Pixelator Mini

- Library state: `ready_for_visualization`
- Identity: model `70067`; pixel_data_controller / Ethernet-to-PLink pixel data converter
- Official source: [https://www.enttec.com/product/led-pixel-control/pixelator-mini-lighting-controller-ethernet-to-spi-pixel-converter/](https://www.enttec.com/product/led-pixel-control/pixelator-mini-lighting-controller-ethernet-to-spi-pixel-converter/) (accessed 2026-09-30)
- Reference envelope: 0.2000 m W × 0.0420 m H × 0.1200 m D
- Control: Art-Net/sACN/ESP Ethernet input to eight proprietary PLink outputs for compatible PLink injectors; not a fixture power supply and not a DMX512 output device.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/enttec/pixelator-mini/fixture.json)
- [Blender model](../../../../assets/fixtures/enttec/pixelator-mini/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/enttec/pixelator-mini/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/enttec/pixelator-mini/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- 200 x 120 x 42 mm unit dimensions
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `pixel_controller` profile with 20 visible meshes and 3,376 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/enttec/pixelator-mini/validation/detail.json) · [Front](../../../../assets/fixtures/enttec/pixelator-mini/previews/front.png) · [Side](../../../../assets/fixtures/enttec/pixelator-mini/previews/side.png) · [Rear](../../../../assets/fixtures/enttec/pixelator-mini/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/enttec/pixelator-mini/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/enttec/pixelator-mini/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
