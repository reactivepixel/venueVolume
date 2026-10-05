---
type: feature-index
status: active
updated: 2026-09-19
---

# Feature Catalog

Venue Volume is a React-based SaaS application for preparing and operating productions in scanned venues. The founder's 2026-10-04 clarification supersedes the original configuration-template room model.

## Confirmed by the founder

- Venues come from a shared scanned-venue library; no raw areas are created.
- A **Load Out** selects physical fixtures and their placement inside one venue. Each venue supports multiple Load Outs.
- A **Tour** uses base fixture inventory across multiple venues with additions per stop. Each stop has its own Load Out and placements.
- Inventory and preparation are managed primarily in SaaS; visionOS refinement comes later.
- Presets, cues and scripts remain reusable programming concepts, separate from physical venue identity and touring logistics.

See [[../Design/SaaS UX Review - Scanned Venues and Load Outs]] for the whole-product review. Earlier feature documents mentioning template-created venues are historical unless updated to this model.

The confirmed live direction adds color-coded pre-programming/programming/live workflows, fixture/group/venue control, a temporary live programmer, MIDI-driven script progress, song restart, inspectable cue targets, and a synchronized touch pop-out.

## Defined features

| ID | Feature | Basis |
| --- | --- | --- |
| F01 | [[F01 - Workspace and access|Workspace and access]] | Proposed SaaS support |
| F02 | [[F02 - Show lifecycle|Show lifecycle]] | Confirmed domain |
| F03 | [[F03 - Configuration templates|Load Outs (replaces configurations)]] | Confirmed domain |
| F04 | [[F04 - Drawings and assets|Drawings and assets]] | Confirmed need; format scope open |
| F05 | [[F05 - Equipment inventory|Equipment inventory]] | Confirmed domain |
| F06 | [[F06 - Fixture profiles and roles|Fixture profiles and roles]] | Supporting requirement |
| F07 | [[F07 - Venue configurations|Venue configurations]] | Confirmed domain |
| F08 | [[F08 - Patch and routing|Patch and routing]] | Supporting DMX requirement |
| F09 | [[F09 - Inheritance and overrides|Inheritance and overrides]] | Confirmed behavior; resolution policy proposed |
| F10 | [[F10 - DMX presets|DMX presets]] | Confirmed domain |
| F11 | [[F11 - Cues and state transitions|Cues and state transitions]] | Confirmed domain |
| F12 | [[F12 - Scripts and running order|Scripts and running order]] | Confirmed domain |
| F13 | [[F13 - Rehearsal and operation|Rehearsal and operation]] | Supporting requirement |
| F14 | [[F14 - Local bridge and diagnostics|Local bridge and diagnostics]] | Proposed architecture required for venue output |
| F15 | [[F15 - History synchronization and portability|History synchronization and portability]] | Supporting requirement |
| F16 | [[F16 - Workflow modes and live programmer|Workflow modes and live programmer]] | Confirmed live-operation direction |
| F17 | [[F17 - Script transport and MIDI triggers|Script transport and MIDI triggers]] | Confirmed MIDI and restart workflows |
| F18 | [[F18 - Persistent console and live updates|Persistent console and live updates]] | Confirmed touch/pop-out requirement |

## Proposed policy requiring validation

Template revision pinning, immutable publication, non-tracking cue evaluation, authenticated local bridge, operator leases, offline behavior, role names, billing entitlements, supported CAD formats, and commercial packaging are proposals. They are deliberately distinguished from the founder's confirmed domain.

## Delivery sequence

1. Validate fixture profiles, venue override resolution, CAD format needs, and local output feasibility.
2. Implement show/template/inventory/venue data and revision semantics.
3. Implement presets, cues, scripts, and simulated venue-resolved rehearsal.
4. Implement authenticated bridge, compiler, preflight, physical output, and recovery with hardware tests.
5. Add SaaS collaboration, audit, imports/exports, and commercially validated billing.

The design study covers all five groups to expose dependencies early. It is not a production release commitment.

## Design and engineering

- [[../Design/Design Overview|Design Overview]]
- [[../Design/Screen Inventory|Screen Inventory]]
- [[../../03 Engineering/Domain Model|Domain Model]]
- [[../../03 Engineering/Service and Runtime Boundaries|Service and Runtime Boundaries]]
