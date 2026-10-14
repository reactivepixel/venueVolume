# Palette editor alternatives

Prepared 7 October 2026. These five original panel concepts are awaiting selection. They do not replace the implemented editor and are not designs by, or endorsed by, the referenced designers. The current SaaS screenshot is a live browser capture with isolated demo data; the current visionOS image is the existing Simulator capture.

All alternatives show a two-step Dimmer wave for four wash fixtures: Full and Blackout palette references, 60 BPM, four beats per cycle and a full phase spread. Sources, fixtures, timing and store/apply actions remain explicit.

| Panel | Visual thesis | Content and workflow | Interaction intent |
| --- | --- | --- | --- |
| 1 Apple HIG | Quiet system glass, familiar split view and large controls. | Pool sidebar, palette editor, numbered steps, grouped timing and selected-fixture application. | Native SwiftUI controls, 60-point gaze targets, system hover/selection, Dynamic Type and Reduce Motion. The strict native implementation target is the HIG; the HTML concept is a layout specification, not a certification of runtime accessibility or system material rendering. |
| 2 grandMA3 | Dense console workspace with yellow selection, numbered pools and a cyan graph. | Fixture/group selection → attribute pool → step/integrated presets → phaser layers → store/update. | Select steps in graph/sheet, use encoder-style controls, recall presets into the programmer. Extended feature groups and layer views in this proposal require implementation; they are not claims about the current simulation engine. |
| 3 Don Norman | Readable neutral surfaces, clear causal relationships and explicit state. | Selection → effect construction → predicted result; changes and preserved attributes remain visible. | Immediate preview, understandable feedback, explicit Apply and reversible edits. |
| 4 Alan Cooper | A calm operator workspace with the result dominant. | Build the desired wave, select two looks, choose rhythm and speed; disclose detailed timing only when needed. | Goal-oriented pattern choice, continuous preview, editable sources and a single Store & apply action. |
| 5 Bret Victor | An editable light score showing every fixture through time. | Linked source shelf → four phase-offset curves → current output and phase ring. | Scrub time, manipulate per-fixture phase, drag sources onto steps and see consequences immediately. Experimental: direct manipulation, curves and arbitrary per-fixture phase require new behavior. |

## Primary references

- [Apple HIG: Windows](https://developer.apple.com/design/human-interface-guidelines/windows), [Layout](https://developer.apple.com/design/human-interface-guidelines/layout), [Design for spatial user interfaces](https://developer.apple.com/videos/play/wwdc2023/10076/). Native window material and system controls must be used for the eventual Apple implementation; no custom window-management chrome is proposed.
- [grandMA3 Phaser Editor](https://help2.malighting.com/grandMA3/2.4/HTML/phaser_editor.html), [Phasers](https://help.malighting.com/grandMA3/2.4/HTML/phaser.html), [Use Preset](https://help.malighting.com/grandMA3/2.5/HTML/presets_use.html).
- [Don Norman: Design as Communication](https://jnd.org/design-as-communication/): make the conceptual model and action/result relationship understandable.
- [Hugh Dubberly's interview with Alan Cooper](https://www.dubberly.com/articles/alan-cooper-and-the-goal-directed-design-process.html): design around the operator's goal and context, rather than accumulating controls.
- [Bret Victor: Learnable Programming](https://worrydream.com/LearnableProgramming/): expose data and intermediate state, allowing people to react to a visible work in progress.

## Wrist entry

The wrist Toolbox's Palettes control is now a launch button for the existing palette editor. It uses the generic serialized editor recall, preserving the current draft and fixture selection. It does not apply a palette merely by opening the editor. The redundant wrist palette browser and its toggle state were removed. Simulator build and session tests passed. This remains on the task branch, not deployed to a headset.

## Reproduce

`python3 build-panels.py` creates `panels.html`. `node render.mjs` captures all five panel-only PNGs using the worktree's Playwright dependency and installed Chrome. The screenshots are static proposal states, not production functionality. `capture-current.mjs` captures the existing SaaS programmer from the worktree's development server on port 5184, using a fresh browser context. The visionOS image was copied unchanged from the validated Simulator capture.
