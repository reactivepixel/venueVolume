# ADJ Focus Spot 4Z

- Library state: `ready_for_visualization`
- Identity: model `FOC200`; Moving head / spot
- Official source: [https://www.adj.com/products/focus-spot-4z](https://www.adj.com/products/focus-spot-4z) (accessed 2026-09-30)
- Reference envelope: 0.2786 m W × 0.4574 m H × 0.1815 m D
- Control: DMX512, RDM; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: fixture-specific editable Blender approximation, meter-scale USDZ, Y-up and -Z forward. Rounded base/control panel, U-yoke, capsule head, tilt hubs, optical barrel, bezel and cooling vents.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/adj/focus-spot-4z/fixture.json)
- [Blender model](../../../../assets/fixtures/adj/focus-spot-4z/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/adj/focus-spot-4z/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/adj/focus-spot-4z/validation/usdz.json)

## Fidelity revision

- Revision 2 replaces the generic proxy with fixture-specific geometry derived from the stored official product image.
- Exact labels, small fasteners, connector geometry, internal mechanisms and photometry remain simplified.

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer specifies L x W x H; runtime X/Y/Z uses W/H/L.
- Moving components are separated but no runtime articulation joints are authored.
