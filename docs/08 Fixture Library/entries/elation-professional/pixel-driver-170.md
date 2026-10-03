# Elation Professional PIXEL DRIVER 170

- Library state: `researched`
- Identity: model `PIX170`; pixel_driver / Compact DMX-to-pixel tape driver for Elation PIXEL TAPE 16IP / 40IP
- Official source: [https://www.elationlighting.com/products/pixel-driver-170](https://www.elationlighting.com/products/pixel-driver-170) (accessed 2026-09-30)
- Reference envelope: 0.1010 m W × 0.0500 m H × 0.0262 m D
- Control: DMX512 input to APA120C pixel tape; one universe up to 170 pixels; separate 12–24 V DC supply required
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/elation-professional/pixel-driver-170/fixture.json)
- [Blender model](../../../../assets/fixtures/elation-professional/pixel-driver-170/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/elation-professional/pixel-driver-170/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/elation-professional/pixel-driver-170/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Manufacturer body dimensions; side mounting tabs visible in photo but excluded from stated size. Display-forward axes rotated from the manufacturer L/W/H list using the photo; 50 mm is face height and 26.2 mm enclosure depth. Mounting tabs excluded.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.
- Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion.

## Detailed model revision

Revision 2 uses a `pixel_driver` profile with 10 visible meshes and 1,880 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/elation-professional/pixel-driver-170/validation/detail.json) · [Front](../../../../assets/fixtures/elation-professional/pixel-driver-170/previews/front.png) · [Side](../../../../assets/fixtures/elation-professional/pixel-driver-170/previews/side.png) · [Rear](../../../../assets/fixtures/elation-professional/pixel-driver-170/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/elation-professional/pixel-driver-170/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/elation-professional/pixel-driver-170/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
