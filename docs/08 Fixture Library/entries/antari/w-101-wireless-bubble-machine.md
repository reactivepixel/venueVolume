# Antari W-101 Wireless Bubble Machine

- Library state: `researched`
- Identity: model `W-101`; equipment / wireless bubble machine
- Official source: [https://antari.com/products/w-101/](https://antari.com/products/w-101/) (accessed 2026-10-02)
- Reference envelope: 0.2640 m W × 0.2900 m H × 0.3500 m D
- Control: On/off and supplied W-1 wireless transmitter are listed by manufacturer; no DMX interface is listed.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/antari/w-101-wireless-bubble-machine/fixture.json)
- [Blender model](../../../../assets/fixtures/antari/w-101-wireless-bubble-machine/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/antari/w-101-wireless-bubble-machine/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/antari/w-101-wireless-bubble-machine/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer L/W/H = 350/264/290 mm mapped to depth/width/height.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/antari/w-101-wireless-bubble-machine/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
