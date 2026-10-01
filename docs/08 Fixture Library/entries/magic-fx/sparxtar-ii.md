# MAGIC FX Sparxtar II

- Library state: `researched`
- Identity: model `MFX5003`; atmospherics / cold-spark effect appliance
- Official source: [https://magicfx.com/products/sparxtar-ii](https://magicfx.com/products/sparxtar-ii) (accessed 2026-09-30)
- Reference envelope: 0.2540 m W × 0.2540 m H × 0.2260 m D
- Control: See source-backed protocol list; compatibility and control system are not implemented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/magic-fx/sparxtar-ii/fixture.json)
- [Blender model](../../../../assets/fixtures/magic-fx/sparxtar-ii/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/magic-fx/sparxtar-ii/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/magic-fx/sparxtar-ii/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Manufacturer publishes a three-axis size but does not label axis names; the two equal 254 mm axes remain interchangeable and 226 mm is assigned depth based on the product image.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `spark` profile with 57 visible meshes and 9,772 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/magic-fx/sparxtar-ii/validation/detail.json) · [Front](../../../../assets/fixtures/magic-fx/sparxtar-ii/previews/front.png) · [Side](../../../../assets/fixtures/magic-fx/sparxtar-ii/previews/side.png) · [Rear](../../../../assets/fixtures/magic-fx/sparxtar-ii/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/magic-fx/sparxtar-ii/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/magic-fx/sparxtar-ii/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
