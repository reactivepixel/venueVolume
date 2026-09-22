---
type: feature
id: F16
status: specified-and-prototyped
owner: product-and-engineering
updated: 2026-09-19
---

# F16 — Workflow modes and live programmer

## Confirmed direction

Venue Volume has three primary uses: pre-programming before arrival, programming at the venue, and live operation. The live surface should be comfortable to front-of-house and lighting engineers accustomed to lighting desks. Early programming remains the foundation, while live operators can adjust individual fixtures, groups, and the whole venue, apply presets, and retain control over script playback.

## Mode contract

| Mode | Color | Purpose | Default effect |
| --- | --- | --- | --- |
| Pre-programming | Violet | Design show defaults, configurations, fixture roles, presets, cues, scripts | Edit drafts / preview |
| Programming | Amber | Adapt and rehearse the selected venue | Edit venue drafts; explicit live adjustments require an armed session |
| Live | Teal | Run scripts and control the room | Acknowledged operator commands against the current run |

Modes are workflow context, not permission grants or physical arming state. Keep their text labels visible alongside color. Changing mode must never silently arm output or stop another active console. Red is reserved for blackout/failure, not used as the normal live-mode accent.

Within the live console, functional sections also require distinct high-contrast tinted surfaces and title bands, plus a single active-section outline and textual indicator for touch/keyboard interaction. Section accents must not imply workflow changes, arming, output authority, or cue activation. Active-section focus is local presentation state and must not be broadcast as a runtime command. Preserve cue/fixture state signals and reserve red for blackout/faults. See [[../Design/Live Console Design]] for the section palette and acceptance checks.

## Selection and programmer

Tap a fixture on the drawing to toggle selection. Group buttons replace the selection with that role's fixtures. Whole venue selects all valid instances. Clear selection changes selection only; it must not release live values. The selected detail panel shows count, roles, intensity, mixed values, color, applicable position controls, and preset choice. Cue inspection can select all reactive targets without calling the cue.

Absolute edits set the selected fixtures to a shared value. Relative nudges adjust each fixture's current parameter separately and clamp to valid ranges. Unsupported attributes are disabled or excluded with a clear explanation. Repeated fixtures remain individually addressable. Selection never activates output by itself.

Live changes enter a temporary **programmer** layer. They do not overwrite the preset, show default, or saved venue override. Release selected returns only those fixtures to cue control; release manual clears the entire programmer. An explicit future record/store workflow must name the destination and scope before persisting a live look.

## Proposed output precedence

1. Resolve the venue-specific cue and selected parameter assignments.
2. Apply manual programmer values per fixture/parameter (including explicit zero).
3. Scale intensity by the fixture group's master and then the grand master.
4. Apply the blackout latch to intensity output.

Color/position are not dimmed by the grand master. Fixture-aware safe output is required; never treat every DMX channel as intensity. The prototype uses exclusive role groups and multiplicative intensity trims. Overlapping groups, HTP/LTP playback combinations, effects, flash/bump behavior, and physical fade timing need a separate validated engine policy. Manual values currently persist through cue calls and song restarts until explicitly released.

## Cross-layer responsibilities

- UI: touch controls, clear manual/cue provenance, visible grand/group masters, separate selection and release actions, selected count, and mixed-state feedback.
- Domain/API: stable fixture/group IDs, capability-aware parameter operations, explicit mode/scope, validated command bounds and authorization.
- Runtime: atomic batch edits, deterministic manual-over-cue composition, idempotent commands, priority for blackout, and actual-state acknowledgements.
- Persistence: temporary runtime programmer separate from durable show and venue programming. Recording into a draft is an explicit operation.
- Operations/tests: verify selected-only effects, multi-fixture nudge, zero, release, group/master scaling, blackout restore, capability mismatch, and operator ownership.

## Prototype coverage

Implemented: all three mode indicators; interactive stage selection across the design study; live intensity/color/preset/pan/tilt preview; group and grand masters; clear selection, release selected, release all; and shared simulated live state. Non-console stage inspectors are local visual previews. Physical DMX, live fades, fixture manufacturer validation, and record/store are not implemented.

Related: [[F10 - DMX presets]], [[F13 - Rehearsal and operation]], [[F17 - Script transport and MIDI triggers]], [[F18 - Persistent console and live updates]].
