---
type: feature
id: F12
status: specified
owner: product-and-engineering
updated: 2026-09-21
---

# F12 — Scripts and running order

## Intent and basis

Confirmed domain. Represent the expected sequence of cues and operator instructions.

The domain requested by the founder is authoritative. Detailed policies below are proposed requirements pending R&D validation, not evidence of implemented production behavior.

## Data and rules

Entities: Script, ScriptRevision, ScriptEntry, AdvancePolicy, VenueScriptOverride.

A script is an ordered list of cue references. The same cue can appear repeatedly using distinct entry IDs. Entry order, notes, manual/timed follow, optional labels, and enabled state are independent of the cue. Venue sequence override is explicit.

## Interface responsibilities

The updated model adds songs/segments, expected relative offsets, MIDI mappings to entry IDs, actual cue-hit markers, a cue-driven timeline, and playback-pass history. Inspection does not activate; explicit call/restart does. See [[F17 - Script transport and MIDI triggers]].

Provide script list, editor, cue insertion, repeat/reorder/remove, notes, advance policy, rehearsal and next-cue preview.

### Vertical numbered cue slots

Display every script occurrence in a vertical numbered slot, both in the editor and the live playback box. Slot numbers are derived 1-based positions, not cue IDs: moving Q02 into slot 04 does not rename Q02. Repeated cues retain distinct entry IDs. Song headers may separate contiguous segments without changing script order or restarting the numbering.

Editing supports dragging a grip with mouse or touch onto another slot; the moved entry is inserted at that slot and intervening entries shift. Show source and destination feedback, support edge scrolling, and cancel without mutation on Escape, pointer cancellation, or dropping outside the list. Arrow keys on a focused grip and explicit up/down buttons provide non-drag alternatives; announce the resulting position. Live operation exposes no drag handles. Its Edit running order action opens the draft editor without replacing the detached live window.

Cue references, MIDI bindings, timing, and notes travel with stable entry IDs. Materialize demo defaults before a move so index-derived fallback values cannot silently change during reordering. Removing one occurrence never removes another occurrence or the cue definition. Reordering an armed session's draft must not fire a cue or immediately replace the accepted live sequence; apply through the existing review flow while retaining the active entry and output.

Wireframe and high-fidelity screens are mapped in [[../Design/Screen Inventory|Screen Inventory]]. See [[../Design/Interaction Coverage|Interaction Coverage]] for what the prototype actually implements.

## API, storage, and service responsibilities

Validate referenced cues and durations; preserve stable entry IDs during reordering. Version entry lists atomically; do not merge by array index. Deleting an entry does not delete its cue.

Production reorder commands should identify script, expected revision, moved entry, and destination entry/anchor; authorize editing at the selected show/venue scope and reject stale or missing targets. Persist the new sequence atomically and derive display slot numbers. Publish a draft revision notification, not a cue activation. Current browser implementation serializes shared updates and cancels a drag when its script changes; full server revision conflicts, audit records, and venue-scoped sequence persistence remain unimplemented.

## Runtime and operational responsibilities

Compile sequence with resolved cues and defined advance behavior. At end of script, hold the final active state until explicit change. Direct cue jumps must explicitly define whether/how script position changes.

## Acceptance scenarios

Reordering entries preserves cue definitions; repeated Q02 entries retain separate notes and timing; a venue-specific sequence does not alter the show sequence; no timer can advance while held or blackout-latched.

Apply tenant isolation, revision conflicts, invalid input, empty/loading/error, and permission checks where relevant. Test against resolved data rather than only the presentation.

## Relationships

- [[Feature Catalog]]
- [[../../03 Engineering/Domain Model|Domain Model]]
- [[../../03 Engineering/Service and Runtime Boundaries|Service and Runtime Boundaries]]
- [[../Design/Screen Inventory|Screen Inventory]]
