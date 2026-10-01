---
type: decision
status: experimental
owner: engineering
updated: 2026-10-01
---

# 0007 — Reversible application audit history

Provide persistent Undo/Redo and an inspectable event list across fixture, preset, room, and saved-setup operations. The wrist toolbox and fixture editor expose Undo/Redo directly; the toolbox History tab restores a selected event's resulting state.

## State and event model

Use an append-only graph of immutable logical-state snapshots. Each change has a UUID, parent, timestamp, and human-readable action title. An ordered audit index records changes, history navigation, and external actions. Undo follows the parent; Redo follows the undone path. Editing after Undo forks, preserving abandoned nodes for explicit restoration. History navigation appends an audit entry and never generates a replacement change node.

Capture fixture identities, transforms, patch, resolved DMX and aim overrides; presets and editor draft; room catalog and active room; named setup catalog and active baseline; selection, preview, blackout, and room lighting. Group nested commands and each slider gesture into one transaction; debounce direct text edits. Flush before navigation and lifecycle suspension. Pending gestures/text are not guaranteed durable under abrupt termination.

Do not replay tracking frames, transient spatial gestures, system window state, or network effects. Log mock sync requests/results with their revision, scan lifecycle events, and load/import failures separately. Restoring invalidates sync acknowledgment; it never sends an external request automatically.

## Persistence and room transitions

The audit cursor becomes authoritative for the visible catalog and current state, including on relaunch. Keep room assets and historical setup files so Undo can hide a newly imported room or saved setup without destroying its redo data. Existing legacy placements/catalogs seed the initial snapshot when no audit exists.

Write new snapshot files once, then atomically replace the event/cursor index. Preserve corrupted journals and report recording failures. This local recovery format is not a tamper-proof compliance ledger and has no pruning or cloud replication policy yet.

Cross-room restoration stages and validates the referenced asset and RealityKit collision data before committing the cursor or replacing the current scene. Failed loading leaves both state and cursor intact. Same-room restoration applies directly and updates working autosave/preset projections. The previous state remains in history when a user restores without saving a named setup.

## Verification

37 Core tests and model/session checks include branch retention, grouped edits, exact state restoration, preset propagation, fixture deletion/aim, saved catalog reversal, relaunch, failed room transitions, sync invalidation, and corrupt journal preservation. Native Simulator integration exercises cross-room Undo/Redo and fixture restoration; the toolbox screenshot shows the resulting event list. Simulator and unsigned device builds pass. Physical pinch gestures, keyboard shortcut routing between simultaneous windows, wrist ergonomics, and long-session headset performance still need device acceptance.

See the [app README](../../apps/visionos/README.md) for usage, storage locations, and test commands.
