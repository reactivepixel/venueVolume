---
type: design-validation
status: prototype
updated: 2026-09-19
---

# Interaction Coverage

Revision 05: script editor and live playback use vertical numbered cue slots. Editor grips support mouse/touch drag to insert at a destination slot, source/target feedback, edge scrolling, Escape/outside-drop cancellation, arrow-key movement, and up/down alternatives. Live slots are inspection-only; Edit running order opens the draft editor. Stable entry IDs retain MIDI, timing, notes, and cue references through moves. Armed sequence changes require review and do not fire a cue. Full server concurrency and venue sequence-override persistence remain outside this prototype.

This is a design prototype. The screen catalog represents intended production surfaces; it does not mean each service exists.

## Implemented for review

- Navigate all 35 screens and preserve screen/fidelity/state in the URL.
- Toggle the same screen between wireframe and high fidelity.
- Inspect generic empty, loading, error/retry, and permission-denied presentations.
- Search shows, configurations, inventory fixtures, profiles, venues, presets, and cues.
- Add local demo show names, templates, venues, presets, fixture instances, and member entries.
- Change preset intensity at show/venue scope, expose provenance, and reset inheritance.
- Modify patch addresses/universes and detect footprint overflow or overlap.
- Reorder, remove, or repeat script cue references using separate entry IDs.
- Arm/disarm simulated playback, advance cues, hold, latch blackout, and simulate connection loss/recovery.
- Export the current local demo model as JSON.
- Retain selected demo data in browser storage. Same-origin window coordination requires available storage; this is not cloud synchronization or production conflict resolution.
- Intercept navigation from marked-dirty editors with a save-and-continue review.

## Live-console revision 02

Implemented: violet pre-programming, amber programming, teal live; touch fixture/group/venue selection; selected intensity/color/preset/compatible position adjustment and relative nudge; group/grand masters; release selected/all manual values; independent cue inspection and activation; reviewed cue/song restart; a single bottom script timeline containing every occurrence in sequence; immediate Back/Next, Hold changing to Play (resume input without advancing), secondary Blackout and House-cue shortcut; actual cue-hit markers; editable song/offsets and venue MIDI mappings; optional permitted Web MIDI input and hardware-free test triggers; synchronized detached console and reviewed draft updates without reload; visible-window wake lock where supported. House calls the demo's existing House open script entry, not separate house-light circuits; production binding configuration remains to implement.

The pop-out remains usable after the editor closes. Active look and manual values survive accepted draft updates; future calls use the new snapshot. Structural patch/fixture changes require disarming.

## Presentation-only or deliberately limited

- Show creation retains the sample production content so the remaining mockups stay reviewable. It does not create independent production databases.
- Many inspector fields, preset colors, cue assignments/timing, and settings illustrate controls but are not bound to a complete domain editor. Their save action is visual/local feedback, not a server write.
- The primary detail/editor examples use Touring rig, Midnight blue, and Q02. Other list entries illustrate the same detail pattern.
- CAD is a schematic interactive stage preview. Selection and parameter preview work, but layer/coordinate controls do not parse or save CAD. Outside the console, parameter edits are local preview values.
- File selection retains filename and size only; no file bytes are uploaded or persisted.
- Non-lighting inventory, fixture channel maps, audit history, conversion results, timings, and revision statuses are sample data.
- Authentication, invitations, password recovery, custom profile creation, cue/script creation dialogs, billing, bridge pairing, template adoption, restore, and archive are review flows only; they do not contact external systems.
- All output, connectivity, live controls, and universe values are simulated. There is no DMX/Art-Net engine, physical interface, or authenticated output lease.
- Blackout/hold logic validates the prototype's advance guard; it does not establish physical device safety or real timing behavior.

Additional limits: no interpolated physical fades, MTC/audio scheduler, verified physical MIDI, full packet deduplication/CC edge policy, or OS always-on-top/background guarantee. Console run keys use demo show/venue names rather than stable production IDs. Expected timeline offsets are metadata; the playhead advances when cues are called.

## Required production expansion

Implement [[../Features/Feature Catalog|the feature contracts]] across API, persistence, compiler, local runtime, and operations. Replace local sample status with authoritative acknowledged state and telemetry freshness. Build complete editors against versioned schemas and verify all controls against their declared effects.
