---
type: screen-index
status: prototype
updated: 2026-09-19
---

# Screen Inventory

The first complete product design baseline has **35 named screens**, each available as a structural wireframe and a high-fidelity mockup. This is the bounded meaning of “every screen” for this design pass; future requirements can extend this catalog. Shared dialogs and states are listed separately so they are not hidden from scope.

Open the React screen browser or the [static gallery](../../../assets/design/venue-volume/index.html). Route pattern: `http://localhost:5173/?screen=<route>&mode=wire` or `mode=hifi`.

## Primary screens

| # | Screen | Route | Feature | Task |
| --- | --- | --- | --- | --- |
| 01 | Sign in | `sign-in` | F01 | Identify the operator and recover access. |
| 02 | Create workspace | `workspace` | F01 | Establish the company workspace and first team. |
| 03 | All shows | `shows` | F02 | Find, duplicate, archive, or create a show. |
| 04 | Create show | `new-show` | F02 | Name the production and set its starting configuration. |
| 05 | Show overview | `overview` | F02 | Understand readiness and continue the next production task. |
| 06 | Configuration templates | `templates` | F03 | Manage reusable rig configurations inside this show. |
| 07 | Template details | `template-detail` | F03 | Inspect a version, its drawing, inventory, and dependent venues. |
| 08 | Template drawing | `template-editor` | F04 | Arrange equipment over a saved technical drawing. |
| 09 | Equipment inventory | `inventory` | F05 | Track lighting and non-lighting production equipment. |
| 10 | Equipment details | `equipment` | F05 | Edit quantity, capability, ownership, and equipment metadata. |
| 11 | Fixture library | `library` | F06 | Find fixture profiles and modes before patching. |
| 12 | Fixture profile | `fixture` | F06 | Inspect channel capabilities, ranges, defaults, and compatibility. |
| 13 | Venues | `venues` | F07 | Compare venue-specific configurations and readiness. |
| 14 | Create venue | `new-venue` | F07 | Seed a venue from a specific template revision. |
| 15 | Venue overview | `venue-detail` | F07 | Review the local configuration and prepare for load-in. |
| 16 | Venue drawing | `venue-layout` | F04 | Adapt the inherited rig to the venue footprint. |
| 17 | DMX patch | `patch` | F08 | Map logical fixtures to addresses with conflict detection. |
| 18 | Compare overrides | `overrides` | F09 | Inspect and reset differences without losing show defaults. |
| 19 | Preset library | `presets` | F10 | Reuse parameter looks across repeated fixture groups. |
| 20 | Preset editor | `preset-editor` | F10 | Program parameters and inspect venue-resolved values. |
| 21 | Cue library | `cues` | F11 | Manage named show states independently from running order. |
| 22 | Cue editor | `cue-editor` | F11 | Assign presets to fixture roles and define transitions. |
| 23 | Scripts | `scripts` | F12 | Choose an expected cue sequence and revision. |
| 24 | Script editor | `script-editor` | F12 | Order cue references, repeats, notes, and advance policies. |
| 25 | Rehearsal | `rehearsal` | F13 | Step through the venue-resolved script with simulated output. |
| 26 | Live console | `live` | F13 | See active and next cue, advance, hold, and blackout. |
| 27 | Output connections | `outputs` | F14 | Pair a bridge and route logical universes to network outputs. |
| 28 | Universe monitor | `universe` | F14 | Inspect individual slot values and output freshness. |
| 29 | Preflight | `preflight` | F13 | Resolve blocking readiness issues before arming. |
| 30 | Connection recovery | `recovery` | F14 | Reconcile stale state and explicitly resume after a disconnect. |
| 31 | Files & drawings | `assets` | F04 | Manage original CAD assets, previews, and revisions. |
| 32 | Activity & versions | `activity` | F15 | Audit edits and restore a reviewed historical revision. |
| 33 | Team & access | `team` | F01 | Invite collaborators with explicit workspace/show permissions. |
| 34 | Show settings | `settings` | F02 | Configure identity, defaults, export, and archive behavior. |
| 35 | Plan & billing | `billing` | F01 | Inspect subscription boundaries without interrupting an active run. |

## Revision 02 extensions

The same 35 routes now include F16–F18. Live/rehearsal adds selection and cue inspectors, manual programmer, masters, a unified bottom song-grouped script timeline with Back/Next/Hold–Play and secondary Blackout/House, MIDI input/mapping, reviewed direct call/song restart, draft-update review, and `popout=1` detached layout. Script editor adds editable song/offset fields. Stage diagrams support selection and parameter preview. See [[Live Console Design]].

## Shared flows and overlays

| Flow | Entry screen | Review behavior |
| --- | --- | --- |
| Password recovery | Sign in | Account email, recovery submit, no actual email |
| Create / duplicate template | Configurations / template detail | Named local template, revision concept |
| Add equipment | Inventory | Named fixture instance in sample dataset |
| Add custom profile | Fixture library | Naming flow; schema editor is future implementation |
| Create preset | Presets | Named local preset card |
| Create cue | Cues | Creation intent; cue persistence is future implementation |
| Create script | Scripts | Creation intent; multiple script persistence is future implementation |
| Add cue reference | Script editor | Select existing cue; allow repeated reference with new entry ID |
| Invite member | Team | Email and role; no external invitation sent |
| Pair bridge | Connections | Pairing code; no physical bridge connection |
| Reset override | Override compare | Confirm removing local scalar override |
| Adopt template revision | Override compare | Example change review; no rebase implementation |
| Restore revision | Activity | Create-new-draft proposal; no history mutation |
| Archive show | Settings | Review active-run constraint; no archive mutation |
| Billing portal | Billing | Provider handoff concept; no billing service |
| Unsaved navigation | Marked-dirty editors | Keep editing or save local demo and continue |

## Shared states

A design-only selector presents populated, empty, loading, error/retry, and permission-denied states on any primary screen. These are reusable structural examples; production copy, actions, and permission rules must be specialized per feature. Connection loss/reconciliation has a dedicated recovery screen. Invalid patch conflicts are exercised using actual demo validation. Run hold, blackout, end-of-script, armed/disarmed, and disconnected states are reachable through the simulated console.

## Export convention

- Wireframes: `assets/design/venue-volume/wireframes/NN-route.png`
- High fidelity: `assets/design/venue-volume/high-fidelity/NN-route.png`
- Mobile examples: `assets/design/venue-volume/mobile/route.png`
- Dialog and state examples: `assets/design/venue-volume/dialogs/` and `states/`
- Full index: `assets/design/venue-volume/manifest.json`

See [[Design Overview]] and [[Interaction Coverage]] before treating an illustrated control as implemented functionality.
