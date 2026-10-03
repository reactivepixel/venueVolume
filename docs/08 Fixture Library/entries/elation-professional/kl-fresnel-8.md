# Elation Professional KL Fresnel 8

- Library state: `ready_for_visualization`
- Identity: model `KLF023`; Fresnel / LED theatrical wash
- Official source: [https://www.elationlighting.com/products/kl-fresnel-8](https://www.elationlighting.com/products/kl-fresnel-8) (accessed 2026-09-30)
- Reference envelope: 0.3275 m W × 0.4560 m H × 0.6084 m D
- Control: DMX, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/elation-professional/kl-fresnel-8/fixture.json)
- [Blender model](../../../../assets/fixtures/elation-professional/kl-fresnel-8/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/elation-professional/kl-fresnel-8/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/elation-professional/kl-fresnel-8/validation/usdz.json)

## Fidelity revision

- Revision 2 replaces the generic proxy with fixture-specific geometry derived from the stored official product image.
- Exact labels, small fasteners, connector geometry, internal mechanisms and photometry remain simplified.

## Assumptions and follow-up

- Detailed procedural visualization model, not manufacturer CAD.
- Manufacturer lists length, width and height individually; runtime X/Y/Z uses width/height/length.
- Moving parts have editable pivots; runtime physics joints are not authored.

## Detailed model revision

Revision 4 uses a `fresnel` profile with 56 visible meshes and 23,496 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/elation-professional/kl-fresnel-8/validation/detail.json) · [Front](../../../../assets/fixtures/elation-professional/kl-fresnel-8/previews/front.png) · [Side](../../../../assets/fixtures/elation-professional/kl-fresnel-8/previews/side.png) · [Rear](../../../../assets/fixtures/elation-professional/kl-fresnel-8/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/elation-professional/kl-fresnel-8/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/elation-professional/kl-fresnel-8/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
