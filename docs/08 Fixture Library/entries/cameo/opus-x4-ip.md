# Cameo OPUS X4 IP

- Library state: `researched`
- Identity: model `CLOX4PIP`; moving light / profile / spot, IP65
- Official source: [https://www.cameolight.com/en/solutions/rental/moving-lights/profile-moving-heads/31933/opus-x4-ip](https://www.cameolight.com/en/solutions/rental/moving-lights/profile-moving-heads/31933/opus-x4-ip) (accessed 2026-10-02)
- Reference envelope: 0.4750 m W × 0.8600 m H × 0.3500 m D
- Control: DMX512, RDM, Art-Net, sACN, W-DMX, CRMX; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/cameo/opus-x4-ip/fixture.json)
- [Blender model](../../../../assets/fixtures/cameo/opus-x4-ip/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/cameo/opus-x4-ip/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/cameo/opus-x4-ip/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Cameo product page labels width 475 mm, height 860 mm, depth 350 mm.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/cameo/opus-x4-ip/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
