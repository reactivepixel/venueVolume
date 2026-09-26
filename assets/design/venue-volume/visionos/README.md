# Venue Volume — visionOS interface drawings

Four design drawings based on the native application in `apps/visionos`. These are illustrations of the interface, not simulator captures. SVG sources retain text and vector geometry; PNGs are rendered previews.

The finished drawings were uploaded successfully to [Venue Volume · visionOS Interface](https://www.figma.com/design/CE6ZZGjlpVf5TRbNAs9eLP?node-id=5-2) in Chapman's Team as editable vector layers.

| Drawing | Figma frame | Editable source | Preview |
| --- | --- | --- | --- |
| Cube and spatial controls | [Open](https://www.figma.com/design/CE6ZZGjlpVf5TRbNAs9eLP?node-id=5-2) | [SVG](01-spatial-interface.svg) | [PNG](01-spatial-interface.png) |
| Placement | [Open](https://www.figma.com/design/CE6ZZGjlpVf5TRbNAs9eLP?node-id=5-126) | [SVG](02-placement.svg) | [PNG](02-placement.png) |
| All 16 channels and element states | [Open](https://www.figma.com/design/CE6ZZGjlpVf5TRbNAs9eLP?node-id=5-200) | [SVG](03-interface-elements.svg) | [PNG](03-interface-elements.png) |
| Launch window | [Open](https://www.figma.com/design/CE6ZZGjlpVf5TRbNAs9eLP?node-id=5-361) | [SVG](04-launch-window.svg) | [PNG](04-launch-window.png) |

## Scope and differences from runtime

- Cyan fixture edges, selected/unselected cube states, name tooltip, patch fields, DMX sliders, and head-following debug panel.
- Sample fixture: Front wash, universe 1, addresses 1–16. Channel values are illustrative.
- The compact inspector shows the first eight controls in a scroll viewport; the element sheet exposes all sixteen.
- The placement reticle and preview cube are explanatory illustrations. The implementation currently exposes a placement grid without these preview elements.
- Glass shading and perspective are drawn approximations; actual materials depend on the visionOS environment.
- The mock sync error excerpt is drawn separately for review. The actual app shows errors inside the same debug panel and reuses its sync button.

## Figma status

All four uploads returned `success: true` and the frame IDs linked above. The local PNGs were visually inspected. Figma's Starter plan tool-call limit blocked final screenshot/export verification inside Figma and cleanup of the earlier native draft frames (`3:2` and `3:6`). Use the direct finished-frame links above. Those drafts contain the initial cube and inspector work and are not the completed drawings.

The visionOS community library was discoverable but denied import access. The finished controls are custom vector drawings based on the Swift source, with SF Pro typography.

## Regenerate

From the repository root:

```sh
python3 apps/visionos/Design/generate_drawings.py
```

PNG previews were rendered with `@resvg/resvg-js`, using the system SF Pro font, at each SVG's intrinsic dimensions. No app source code changed for these drawings.
