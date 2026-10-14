# visionOS palette editor refinements — proposals 16–25

Question: which hierarchy makes tempo, palette sources, a selected phaser step and live output feel like one coherent editing task?

Ten native variants requested by the user, overriding the prototype skill's default five-variant cap. They use a separate native SwiftUI prototype target, sharing the earlier preview drawing approach, instead of a browser route because the user specifically rejected SaaS-oriented layouts. Launch argument `--proposal 16` through `25` is the native equivalent of variant routing. This is throwaway design code with no production mutations.

Visual thesis: one native glass window, a strong palette title, aligned functional groups, restrained blue selection, and space around gaze targets.
Content plan: palette identity → rhythm and selected step → causal preview → selection-specific apply action. Library and advanced details use progressive disclosure.
Interaction thesis: standard gaze hover and pinch activation; expanding step selection; synchronized preview and swatches, with reduced motion respected. No decorative motion.

Structural alternatives: 16 balanced split; 17 output first; 18 native library sidebar; 19 horizontal step drawer; 20 focused rhythm/step tabs; 21 source shelf; 22 step-focused inspector; 23 rhythm and result columns; 24 compact editor with separate library sheet; 25 fixture score.

Sources: [Spatial layout](https://developer.apple.com/design/human-interface-guidelines/spatial-layout), [Layout](https://developer.apple.com/design/human-interface-guidelines/layout), [Materials](https://developer.apple.com/design/human-interface-guidelines/materials), [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons), [Ornaments](https://developer.apple.com/design/human-interface-guidelines/ornaments).

Use system glass rather than opaque window backgrounds; native window management; content within window bounds; an ornament for selected-fixture actions only, not supplemental content; consistent primary/secondary typography; large, separated controls. These prototypes apply the guidance, but are not a claim of full HIG compliance or headset accessibility certification.


## Run and capture

With a visionOS simulator booted, run `./run.sh 16` from this directory, substituting 16–25 for another proposal. The script builds and installs only the design prototype. `python3 capture.py` captures all ten, or pass a list of numbers to capture selected variants. Each launch prints the initial relevant state. No show files, saves, or fixtures are mutated.

Captured state: 8 steps, step 3, 120 BPM, 4/4, two bars, Full palette source, four selected fixtures. 20 demonstrates progressive disclosure: the rhythm ring is in the Rhythm tab, while the screenshot shows Steps. The compact layout keeps the library behind its header action. The bar shortcuts assume one step per beat; full production timing must preserve step width, measure and speed as separate concepts.

Validation: native simulator build succeeded; all ten were launched, captured, and visually inspected. Overfull drawers and a compact layout were repaired. Screenshots are real native simulator pixels cropped around the window and context ornament. Full-room originals remain in ignored Captures/. This is a visual prototype: Save/Apply are placeholders; template and source handlers demonstrate selection only. Headset comfort, accessibility scaling, complete editor behavior, data-model integration and persistence are not validated here.

Preview swatches are procedural SwiftUI Canvas samples, carrying forward the prior shader study. Preview playback and swatches respect Reduce Motion. Window glass, standard buttons, segmented controls, slider, popover and sheet use native SwiftUI rendering.

No winning design has been selected. These artifacts stay on the task branch; production implementation awaits the user's choice.
