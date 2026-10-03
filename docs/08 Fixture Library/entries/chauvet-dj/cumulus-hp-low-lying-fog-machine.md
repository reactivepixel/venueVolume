# CHAUVET DJ Cumulus HP Low-Lying Fog Machine

- Library state: `researched`
- Identity: model `Cumulus HP`; atmospherics / ultrasonic water-mist low fogger
- Official source: [https://www.chauvetdj.com/products/cumulus-hp/](https://www.chauvetdj.com/products/cumulus-hp/) (accessed 2026-09-30)
- Reference envelope: 0.3040 m W × 0.3470 m H × 0.4640 m D
- Control: See source-backed protocol list; compatibility and control system are not implemented.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/chauvet-dj/cumulus-hp-low-lying-fog-machine/fixture.json)
- [Blender model](../../../../assets/fixtures/chauvet-dj/cumulus-hp-low-lying-fog-machine/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/chauvet-dj/cumulus-hp-low-lying-fog-machine/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/chauvet-dj/cumulus-hp-low-lying-fog-machine/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- The manual's drawing and specifications label the bare enclosure length 464 mm, width 304 mm, height 347 mm. External output hose and floor nozzle are not included in this housing envelope.
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.
- No official product image URL was present in the research CSV.

## Detailed model revision

Revision 2 uses a `low_fog` profile with 112 visible meshes and 20,628 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/chauvet-dj/cumulus-hp-low-lying-fog-machine/validation/detail.json) · [Front](../../../../assets/fixtures/chauvet-dj/cumulus-hp-low-lying-fog-machine/previews/front.png) · [Side](../../../../assets/fixtures/chauvet-dj/cumulus-hp-low-lying-fog-machine/previews/side.png) · [Rear](../../../../assets/fixtures/chauvet-dj/cumulus-hp-low-lying-fog-machine/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/chauvet-dj/cumulus-hp-low-lying-fog-machine/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/chauvet-dj/cumulus-hp-low-lying-fog-machine/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
