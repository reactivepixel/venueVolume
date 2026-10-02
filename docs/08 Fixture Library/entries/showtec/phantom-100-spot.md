# Showtec Phantom 100 Spot

- Library state: `ready_for_visualization`
- Identity: model `40077`; moving light / LED moving spot
- Official source: [https://www.showtec-lights.com/en/40077-phantom-100-spot.html](https://www.showtec-lights.com/en/40077-phantom-100-spot.html) (accessed 2026-10-02)
- Reference envelope: 0.3250 m W × 0.4200 m H × 0.2100 m D
- Control: DMX512; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/showtec/phantom-100-spot/fixture.json)
- [Blender model](../../../../assets/fixtures/showtec/phantom-100-spot/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/showtec/phantom-100-spot/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/showtec/phantom-100-spot/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Showtec lists mechanical length 325 mm, width 210 mm, height 420 mm; in upright head pose, length is mapped to front-back depth.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `moving_spot` profile with 85 visible meshes and 18,060 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/showtec/phantom-100-spot/validation/detail.json) · [Front](../../../../assets/fixtures/showtec/phantom-100-spot/previews/front.png) · [Side](../../../../assets/fixtures/showtec/phantom-100-spot/previews/side.png) · [Rear](../../../../assets/fixtures/showtec/phantom-100-spot/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/showtec/phantom-100-spot/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/showtec/phantom-100-spot/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
