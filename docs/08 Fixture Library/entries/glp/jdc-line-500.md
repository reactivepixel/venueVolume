# GLP JDC Line 500

- Library state: `ready_for_visualization`
- Identity: model `JDC Line 500`; Strobe / blinder / linear hybrid strobe
- Official source: [https://glp.de/de/produkte/entertainment-lighting/strobes/jdc-line-500](https://glp.de/de/produkte/entertainment-lighting/strobes/jdc-line-500) (accessed 2026-09-30)
- Reference envelope: 0.5070 m W × 0.0740 m H × 0.2015 m D
- Control: DMX, RDM, Art-Net, sACN; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.
- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.
- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.

## Local assets

- [Fixture record](../../../../assets/fixtures/glp/jdc-line-500/fixture.json)
- [Blender model](../../../../assets/fixtures/glp/jdc-line-500/models/fixture.blend)
- [USDZ model](../../../../assets/fixtures/glp/jdc-line-500/models/fixture.usdz)
- [USDZ validation](../../../../assets/fixtures/glp/jdc-line-500/validation/usdz.json)

## Assumptions and follow-up

- Procedural visualization proxy, not manufacturer CAD.
- Manufacturer specifies H x W x D.
- Moving components are separated but no runtime articulation joints are authored.
