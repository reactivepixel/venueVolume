# Martin Professional (HARMAN) MAC Aura Raven XIP

- Library state: `ready_for_visualization`
- Identity: model `MAC Aura Raven XIP`; moving light / IP-rated wash / Aura pixel effect
- Official source: [https://www.martin.com/en-US/products/mac-aura-raven-xip](https://www.martin.com/en-US/products/mac-aura-raven-xip) (accessed 2026-10-02)
- Reference envelope: 0.4290 m W × 0.6030 m H × 0.2850 m D
- Control: DMX, RDM, Art-Net, RDM over Art-Net, sACN, Martin P3; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/martin-professional-harman/mac-aura-raven-xip/fixture.json)
- [Blender model](../../../../assets/fixtures/martin-professional-harman/mac-aura-raven-xip/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/martin-professional-harman/mac-aura-raven-xip/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/martin-professional-harman/mac-aura-raven-xip/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer physical specs: base width 429 mm, maximum height 603 mm, base depth 285 mm; across-yoke width is 528 mm.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 416 visible meshes and 65,404 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/martin-professional-harman/mac-aura-raven-xip/validation/detail.json) · [Front](../../../../assets/fixtures/martin-professional-harman/mac-aura-raven-xip/previews/front.png) · [Side](../../../../assets/fixtures/martin-professional-harman/mac-aura-raven-xip/previews/side.png) · [Rear](../../../../assets/fixtures/martin-professional-harman/mac-aura-raven-xip/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/martin-professional-harman/mac-aura-raven-xip/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/martin-professional-harman/mac-aura-raven-xip/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
