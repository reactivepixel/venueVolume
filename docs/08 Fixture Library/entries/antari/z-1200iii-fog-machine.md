# Antari Z-1200III Fog Machine

- Library state: `ready_for_visualization`
- Identity: model `Z-1200III`; equipment / heated fog machine
- Official source: [https://antari.com/products/z-1200iii/](https://antari.com/products/z-1200iii/) (accessed 2026-10-02)
- Reference envelope: 0.3200 m W × 0.3260 m H × 0.4580 m D
- Control: DMX512, manual, timer, optional wireless, optional cable remote; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/antari/z-1200iii-fog-machine/fixture.json)
- [Blender model](../../../../assets/fixtures/antari/z-1200iii-fog-machine/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/antari/z-1200iii-fog-machine/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/antari/z-1200iii-fog-machine/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer labels L/W/H = 458/320/326 mm, mapped length to front-to-back depth and width to lateral axis.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `fogger` profile with 71 visible meshes and 12,276 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/antari/z-1200iii-fog-machine/validation/detail.json) · [Front](../../../../assets/fixtures/antari/z-1200iii-fog-machine/previews/front.png) · [Side](../../../../assets/fixtures/antari/z-1200iii-fog-machine/previews/side.png) · [Rear](../../../../assets/fixtures/antari/z-1200iii-fog-machine/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/antari/z-1200iii-fog-machine/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/antari/z-1200iii-fog-machine/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
