# Eurolite LED KLS-120 Compact Light Set

- Library state: `ready_for_visualization`
- Identity: model `42109606`; light fixture / four-spot RGBW light bar
- Official source: [https://www.steinigke.de/mpn42109606-eurolite-led-kls-120-kompakt-lichtset.html](https://www.steinigke.de/mpn42109606-eurolite-led-kls-120-kompakt-lichtset.html) (accessed 2026-10-02)
- Reference envelope: 0.6160 m W × 0.2260 m H × 0.1000 m D
- Control: DMX512; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/eurolite/led-kls-120-compact-light-set/fixture.json)
- [Blender model](../../../../assets/fixtures/eurolite/led-kls-120-compact-light-set/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/eurolite/led-kls-120-compact-light-set/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/eurolite/led-kls-120-compact-light-set/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer page explicitly labels width, height and depth for the assembled crossbar.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `batten` profile with 90 visible meshes and 32,408 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/eurolite/led-kls-120-compact-light-set/validation/detail.json) · [Front](../../../../assets/fixtures/eurolite/led-kls-120-compact-light-set/previews/front.png) · [Side](../../../../assets/fixtures/eurolite/led-kls-120-compact-light-set/previews/side.png) · [Rear](../../../../assets/fixtures/eurolite/led-kls-120-compact-light-set/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/eurolite/led-kls-120-compact-light-set/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/eurolite/led-kls-120-compact-light-set/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
