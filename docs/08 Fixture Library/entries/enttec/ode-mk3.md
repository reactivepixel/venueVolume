# ENTTEC ODE Mk3

- Library state: `ready_for_visualization`
- Identity: model `70407`; lighting_network_node / two-universe Ethernet-to-DMX/RDM gateway
- Official source: [https://www.enttec.com/product/dmx-ethernet/ode-mk3-dmx-ethernet-converter/](https://www.enttec.com/product/dmx-ethernet/ode-mk3-dmx-ethernet-converter/) (accessed 2026-09-30)
- Reference envelope: 0.1288 m W × 0.0400 m H × 0.0580 m D
- Control: Ethernet eDMX input to two 5-pin DMX ports; bi-directional eDMX/DMX conversion with Art-RDM. Power by PoE or 12-24 V DC. It is a gateway/node, not a fixture and not a console.
- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/enttec/ode-mk3/fixture.json)
- [Blender model](../../../../assets/fixtures/enttec/ode-mk3/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/enttec/ode-mk3/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/enttec/ode-mk3/validation/usdz.json)

## Assumptions and follow-up

- Original image-informed procedural model, not manufacturer CAD.
- 128.8 x 58 x 40 mm; manufacturer CAD drawing, mapped as long side x short side x body height
- Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.

## Detailed model revision

Revision 2 uses a `node` profile with 12 visible meshes and 1,872 triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.

[Detail and parity report](../../../../assets/fixtures/enttec/ode-mk3/validation/detail.json) · [Front](../../../../assets/fixtures/enttec/ode-mk3/previews/front.png) · [Side](../../../../assets/fixtures/enttec/ode-mk3/previews/side.png) · [Rear](../../../../assets/fixtures/enttec/ode-mk3/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/enttec/ode-mk3/previews/three-quarter.png)

## Independent saved-file audit

[Blender / USDZ parity](../../../../assets/fixtures/enttec/ode-mk3/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.
