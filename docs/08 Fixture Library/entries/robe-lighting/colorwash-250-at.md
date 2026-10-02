# ROBE Lighting ColorWash 250 AT

- Library state: `researched`
- Identity: model `ColorWash 250 AT`; moving light / wash
- Official source: [https://www.robe.cz/res/downloads/catalogues/ColorWash_250_AT_leaflet.pdf](https://www.robe.cz/res/downloads/catalogues/ColorWash_250_AT_leaflet.pdf) (accessed 2026-10-02)
- Reference envelope: 0.4190 m W × 0.5130 m H × 0.4380 m D
- Control: USITT DMX-512; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/robe-lighting/colorwash-250-at/fixture.json)
- [Blender model](../../../../assets/fixtures/robe-lighting/colorwash-250-at/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/robe-lighting/colorwash-250-at/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/robe-lighting/colorwash-250-at/validation/usdz.json)

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Official manufacturer leaflet drawing gives front width 419 mm and height 513 mm head horizontal / 502 mm in alternate pose; side depth 438 mm. Used the maximum stated height.
- Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.
- Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.

## Detailed model revision

Revision 2 uses a `moving_wash` profile with 82 visible meshes and 26,200 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/robe-lighting/colorwash-250-at/validation/detail.json) · [Front](../../../../assets/fixtures/robe-lighting/colorwash-250-at/previews/front.png) · [Side](../../../../assets/fixtures/robe-lighting/colorwash-250-at/previews/side.png) · [Rear](../../../../assets/fixtures/robe-lighting/colorwash-250-at/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/robe-lighting/colorwash-250-at/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/robe-lighting/colorwash-250-at/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
