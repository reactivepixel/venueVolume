# Palette and phaser proposals — round two

Five panel proposals, numbered 6–10 to continue the previous batch. These are browser-rendered design proposals, not screenshots of deployed visionOS or SaaS changes.

| Proposal | Composition |
| --- | --- |
| 6 · Orbit workspace | Green library, central tap-tempo ring, output beside it, expanded inspector on the right. |
| 7 · Glass studio | Grey glass treatment, wide live preview, three editing columns underneath. |
| 8 · Rhythm desk | Dark console workspace with a horizontal step configuration tray. |
| 9 · Preview first | Large output preview and fixture score; compact tempo and step rail on the right. |
| 10 · Tempo canvas | Warm canvas, orbital tempo control, fixture score and attached step pane. |

## Shared interaction proposal

- Tap the central BPM value repeatedly to calculate tempo.
- A 1–16 step slider places numbered, selectable steps around that value.
- Quarter-bar, half-bar, one-bar, two-bar and four-bar shortcuts load 1, 2, 4, 8 and 16 steps. This batch explicitly assumes 4/4 and one step per beat; production timing must keep measure, step width and speed distinct.
- Selecting a number opens the step configuration. The screenshots show step 3 selected.
- Presaved step configurations and recently used configurations offer quick value/transition setup. These represent single-step configurations; Wave, Breathe and Pulse operate on the overall phaser, rather than nesting a complete dynamic phaser inside a step.
- A flat four-fixture beam preview and animated line graph replace the proposed 3D editor preview.
- Pool items use procedural WebGL swatches: moving intensity bands, a breathing glow, pulse stripes, color blending and a moving beam. Static palettes remain static. The PNGs capture a still frame; the HTML animates these previews and respects reduced motion.
- The footer contains only the selected palette summary and its update/apply actions.

## Prototype and validation

Open `panels.html?concept=6` through `?concept=10` in a browser. Without a query, it opens proposal 6. The HTML is self-contained. This prototype demonstrates tempo, step counts, measure shortcuts, step expansion, step presets and pattern changes. Other controls are visual proposals, with no production persistence or fixture connection.

From the worktree root, after the design-studio dependencies are installed:

```sh
node 'docs/03 Design/palette-proposals-round2/render.mjs'
```

The export uses local Chrome and Playwright, captures every panel at 2340 × 1530, checks for clipped controls, and exercises tap tempo, slider counts, measure shortcuts, step expansion, presets and patterns in all five layouts. Screenshots were also visually reviewed.

## Research carried forward

- [MA Lighting: Measure](https://help.malighting.com/grandMA3/2.4/HTML/keyword_measure.html) — measure and speed determine the duration of a phaser cycle; step widths determine how it is divided.
- [MA Lighting: Phasers](https://help.malighting.com/grandMA3/2.2/HTML/phaser.html) — step-based attribute values, speed and phase.
- [Apple: Motion](https://developer.apple.com/design/human-interface-guidelines/motion) — meaningful motion and accessible alternatives.
- [Apple: Reduced Motion evaluation](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria) — adapting continuous movement to accessibility preferences.
