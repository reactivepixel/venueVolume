---
type: backlog
status: active
owner: r-and-d
updated: 2026-09-19
---

# R&D Backlog

## Now: reduce foundational uncertainty

- [ ] Validate the [[../02 Product/Design/Live Console Design|touch console]] with experienced FOH/lighting engineers, including concurrent editing in another window.
- [ ] Test band MIDI Note/CC/Program input, duplicate messages, disconnect, restart generations, and the need for MTC/clock/Show Control.
- [ ] Validate programmer precedence, group/grand masters, release, and multi-fixture edits on hardware.
- [ ] Choose production desktop/window packaging and authoritative bridge subscriptions; verify background execution and window continuity.

- [ ] Validate [[../03 Engineering/Domain Model|show and venue inheritance]] with zero values, resets, template updates, repeated cues, and sibling-venue isolation.
- [ ] Resolve supported CAD formats, required editing depth, units, and conversion licensing using representative drawings.
- [ ] Spike authenticated browser-to-local-bridge connectivity and offline authorization on candidate platforms.
- [ ] Decide cue tracking/release rules, conflicting assignment precedence, interruption, hold, and blackout semantics.
- [ ] Review the [[../02 Product/Design/Screen Inventory|35-screen design baseline]] with programmers, operators, and production managers.

- [ ] Interview representative users using [[../99 Templates/User Interview|the interview template]].
- [ ] Select a small, diverse fixture and interface test matrix.
- [ ] Measure frame rate, jitter, and input-to-output latency on candidate platforms.
- [ ] Compare USB-DMX, Art-Net, and sACN library/hardware options.
- [ ] Model conventional dimmers, RGB/RGBW fixtures, moving heads, and multi-cell fixtures.
- [ ] Prototype parameter ownership when manual input, cues, and effects overlap.
- [ ] Define expected blackout, freeze, disconnect, and reconnect behavior.

## Next: prove the workflow

- [ ] Build a thin walking skeleton: fixture definition → patch → control → output.
- [ ] Test patching and first-look creation with target users.
- [ ] Prototype cue playback and live overrides.
- [ ] Test persistence, autosave, recovery, and show portability.
- [ ] Evaluate keyboard, MIDI, OSC, and touch control needs.
- [ ] Establish a repeatable hardware-in-the-loop test rig.

## Later: product-shaping questions

- [ ] Validate packaging and pricing assumptions.
- [ ] Investigate fixture library licensing and contribution workflows.
- [ ] Evaluate previsualization or 3D integration.
- [ ] Explore remote-control and multi-device workflows.
- [ ] Define update, diagnostics, and support strategy.

## Exit criteria for R&D

R&D can move into focused product development when:

- A first user segment and core job are supported by direct evidence.
- A prototype completes the core workflow with representative hardware.
- Timing and recovery requirements are quantified and met consistently.
- The fixture/show model supports the selected initial scope.
- The largest remaining risks are product execution risks rather than unanswered feasibility questions.

## Practice

Create one note per material experiment from [[../99 Templates/Experiment|the experiment template]]. Link results back here, then convert durable conclusions into product/engineering notes or a decision record.
