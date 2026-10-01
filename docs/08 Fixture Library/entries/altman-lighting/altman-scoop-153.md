# Altman Lighting Altman Scoop 153

- Library state: `researched`
- Identity: model `153`; flood / 10-inch scoop/worklight, 400 W incandescent, soft-edged flood
- Official source: [https://www.altmanlighting.com/wp-content/uploads/2018/10/Scoop153_Disc_Oct2018.pdf](https://www.altmanlighting.com/wp-content/uploads/2018/10/Scoop153_Disc_Oct2018.pdf) (accessed 2026-09-30)
- Reference envelope: 0.2730 m W × 0.3590 m H × 0.2030 m D
- Control: Passive medium-screw incandescent socket; external dimmer only with compatible lamp
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/altman-lighting/altman-scoop-153/fixture.json)
- [Blender model](../../../../assets/fixtures/altman-lighting/altman-scoop-153/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/altman-lighting/altman-scoop-153/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/altman-lighting/altman-scoop-153/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- Manufacturer assembled side/front drawing; no package dimensions used.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.
- No official product image URL was present in the research CSV.

## Detailed model revision

Revision 2 uses a `flood` profile with 8 visible meshes and 2,852 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/altman-lighting/altman-scoop-153/validation/detail.json) · [Front](../../../../assets/fixtures/altman-lighting/altman-scoop-153/previews/front.png) · [Side](../../../../assets/fixtures/altman-lighting/altman-scoop-153/previews/side.png) · [Rear](../../../../assets/fixtures/altman-lighting/altman-scoop-153/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/altman-lighting/altman-scoop-153/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/altman-lighting/altman-scoop-153/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
