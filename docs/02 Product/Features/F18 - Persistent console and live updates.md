---
type: feature
id: F18
status: specified-and-prototyped
owner: product-and-engineering
updated: 2026-09-19
---

# F18 — Persistent console and live updates

## Confirmed direction

The live console is a touch-oriented surface that can pop out into a separate, continuously available window. Editing the current venue elsewhere must update the console without reloading it. Navigation in the editor must not stop playback or reset live controls.

## Window and session contract

A pop-out pins its show and venue context and subscribes to the same run as other consoles for that context. It has its own fixture selection and inspected cue, but shares playback, programmer values, masters, blackout, and hit history. Closing or navigating the editor must not destroy the detached console. A new venue has a different session; its adjustments cannot leak into a sibling venue.

The browser prototype supports a separate named window and an opt-in screen wake lock. It does not guarantee OS-level always-on-top, background execution, or continued operation when all browser windows/processes close. A released wake lock is visible and reacquired on visibility when requested. A production local bridge owns the run independently of the browser; a desktop companion may provide stronger window/always-on-top behavior.

## Updates without surprise output

Separate arrival of an edit from applying it to the runtime:

| Change | Console behavior |
| --- | --- |
| New draft from another editor | Notify and update draft availability without reload |
| Accepted programming/script/MIDI update | Apply to future cue calls; retain current cue values and manual programmer |
| Live fixture/parameter/master command | Apply immediately through the authorized command path, then acknowledge |
| Fixture, profile, routing, or patch change | Require validation and a controlled disarmed transition |
| Removal of the active script entry | Reject while armed; require reconciliation |

When disarmed, the prototype accepts the latest draft automatically. When armed, it exposes Review & apply. Accepting a new preset does not retroactively replace an already active look; the next call or explicit reassert uses the new definition. Cue identity and script occurrence identity stay stable across updates.

## Cross-layer responsibilities

- UI: detached chrome, large touch targets, persistent transport controls, visible sync/draft/armed status, no reload on edits, and local-only selection state.
- API: authenticated subscriptions scoped to show/venue, revision-aware draft events, authorization changes, snapshots and reconnect cursors.
- Runtime: one command authority, ordered/idempotent commands, runtime revision transitions, output ownership, current-look preservation, and no duplicate MIDI receiver.
- Persistence: separate run session/event history from editable draft and publication; do not infer that a browser cache is a production run authority.
- Operations: timestamp telemetry, show staleness, recover after editor/window failure, handle lease loss and revision conflicts, and measure synchronization latency.

## Prototype implementation and acceptance

The same-origin demo uses BroadcastChannel plus storage notifications, localStorage snapshots, and Web Locks to serialize changes. Run state is keyed by demo show name and venue name, with rehearsal separated. Production must replace these demo names with stable IDs and local storage coordination with the bridge's authoritative session protocol. Concurrent draft edits are last-write behavior, not production conflict resolution.

Acceptance: open editor and pop-out; change a venue preset; see update availability without navigation; apply it for future calls; change a master in either console and observe both; close the editor and continue GO from the pop-out. Also test separate venue isolation, MIDI ownership, blocked popups, unsupported wake locks, denied storage, disconnection, and reconnect state. No physical output continuity is claimed by the browser mockup.

Related: [[F13 - Rehearsal and operation]], [[F14 - Local bridge and diagnostics]], [[F15 - History synchronization and portability]], [[F16 - Workflow modes and live programmer]], [[F17 - Script transport and MIDI triggers]].
