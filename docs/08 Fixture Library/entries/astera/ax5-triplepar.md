# Astera AX5 TriplePAR

- Library state: `ready_for_visualization`
- Identity: model `AX5-BTB`; par / battery-powered RGBAW PAR
- Official source: [https://astera-led.com/fr/products/ax5-triplepar/specs/](https://astera-led.com/fr/products/ax5-triplepar/specs/) (accessed 2026-10-02)
- Reference envelope: 0.1936 m W × 0.2135 m H × 0.1481 m D
- Control: DMX512, CRMX, UHF, Bluetooth, Wi-Fi; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/astera/ax5-triplepar/fixture.json)
- [Blender model](../../../../assets/fixtures/astera/ax5-triplepar/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/astera/ax5-triplepar/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/astera/ax5-triplepar/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer dimensions with bracket: L148.1 × W193.6 × H213.5 mm; mapped to depth × width × height in the bracketed pose. Body without bracket is Ø153.2 × H140.5 mm.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `par` profile with 51 visible meshes and 17,736 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/astera/ax5-triplepar/validation/detail.json) · [Front](../../../../assets/fixtures/astera/ax5-triplepar/previews/front.png) · [Side](../../../../assets/fixtures/astera/ax5-triplepar/previews/side.png) · [Rear](../../../../assets/fixtures/astera/ax5-triplepar/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/astera/ax5-triplepar/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/astera/ax5-triplepar/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
