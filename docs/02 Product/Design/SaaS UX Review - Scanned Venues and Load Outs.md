---
type: design-review
status: reviewed-with-open-gaps
owner: product-and-engineering
updated: 2026-10-04
---

# SaaS UX review — scanned venues, Load Outs and Tours

## Conclusion

The previous SaaS study used the wrong preparation hierarchy: Show → configuration template → venue copy. It conflated the physical room, equipment ownership, placement and programming scope. The revised product starts with a shared scanned venue library. A **Load Out** selects physical fixtures and records their placement and patch inside one venue. A venue can have multiple Load Outs. A **Tour** selects a shared base inventory and gives every venue stop its own Load Out, with additions specific to that stop.

This review covers the whole SaaS surface, including the earlier 35-screen study, standalone intake, preparation, programming, operation and workspace management. It is an expert workflow/code review with desktop and mobile browser verification, not user research or a claim of production readiness. The native app was considered as a future handoff destination; it was not changed.

## Product rules

- A venue is a physical room represented by a processed, imported scan. No blank-area creation or CAD-to-room creation.
- Upload → process → inbox → import scan → create Load Out. Import does not choose a show, Tour, inventory template or rig.
- Workspace fixture inventory identifies actual units. A profile describes a model/mode; it is not itself owned equipment.
- A Load Out belongs to one venue. Selection, placement, patch and preparation review belong to that Load Out, not to the room globally.
- Multiple Load Outs may refer to the same physical units as alternative plans. This does not guarantee simultaneous availability.
- A Tour has base unit IDs and ordered stops. Each stop references a venue and owns a distinct Load Out, including repeated visits to the same venue.
- A stop inherits the base inventory selection, never another room’s coordinates or patch. Local additions do not alter the Tour base.
- Existing Load Outs review base changes explicitly. Removed base units remain local additions until deliberately unplaced and deselected, so adoption cannot silently delete placements.
- SaaS is the primary preparation interface. A later visionOS release will refine the same Load Out and fixture identities. No current sync action should imply this already works.
- Presets, cues and scripts remain programming concepts. “Show” may describe reusable programming; it must not own the physical venue or substitute for Tour or Load Out.

## Findings and disposition

| Priority | Finding / consequence | Disposition |
| --- | --- | --- |
| P0 | A raw venue could be created by entering a name and selecting a template; it had no captured room. | Fixed in the active product. Only imported ready scans are offered for Load Outs or stops. Legacy creation links route to movie upload. |
| P0 | Venue names and shared global fixture arrays stood in for identities. Different plans could appear to edit the same rig. | New workspace entities use stable UUIDs. Load Outs own placement and patch maps. Programming preview storage/session keys include the Load Out ID. |
| P0 | Configurations, venues and show inventory each appeared to own the rig. | Replaced top-level configuration navigation with Load Outs; clearly separated inventory, scan and plan ownership. |
| P1 | A Tour existed only as text in a show name. | Added Tours, base selection, ordered stops and dedicated Load Outs. |
| P1 | Local venue additions could be mistaken for upstream inventory edits. | Source badges distinguish Tour base and venue additions; adoption has an explicit review. |
| P1 | Processing success looked like complete venue configuration. | Both upload paths leave a scan in the inbox. Import adds it to the shared library; fixture setup happens later. |
| P1 | Duplicate/quantity operations could imply manufacturing equipment. | Duplicate Load Out copies plan data with the same unit IDs. Referenced units cannot be deleted. Placed units must be returned before deselection. |
| P1 | Readiness, occupancy and progress were largely static demonstration values. | Core Load Out checklist derives from actual selected units, placement, patch conflicts, scan review and pending base changes. It is explicitly a planning check. Legacy operation screens are labeled previews. |
| P1 | Generic venue drawing suggested the SaaS displayed the captured room. | Replaced with an explicitly labeled coordinate schematic linked to the scan. Actual browser Gaussian rendering, metric calibration and direct spatial manipulation remain open release blockers for spatial preparation. |
| P1 | Programming pages contain sample cues, fixed fixture groups and preview-only operations. | Retained as clearly labeled design previews, scoped by Load Out. Production targeting, inheritance, cue CRUD and dependency validation remain open. |
| P1 | Sign-in, invitation, restoration and billing forms returned simulated success. | Active workspace pages now state unavailable capabilities instead of presenting fake account/service actions. |
| P1 | Browser storage could be mistaken for SaaS synchronization. | Persistent local-prototype notice, local save messaging, workspace export and clear server/local storage boundaries. Production cloud persistence remains open. |
| P2 | Navigation started with “Show,” hiding rooms and physical equipment. | Persistent workspace navigation: overview, scanned venues, Load Outs, fixture inventory, Tours, programming, rehearsal/live, files, activity, team, settings, billing. |
| P2 | Empty and mobile views offered little task guidance. | Guided empty states, import prerequisite, searchable lists, horizontal mobile navigation and contained dense tables. |
| P2 | Native follow-up implied handoff availability. | Explicit future visionOS handoff description; JSON export is a plan artifact, not a device sync operation. |

## Whole-product screen review

| Previous screens | Current workflow / decision |
| --- | --- |
| Sign in; create workspace | Authentication and workspace provisioning unavailable locally. Do not collect credentials in a simulation. Production needs tenant membership and role enforcement. |
| Shows; new show; overview | Workspace overview directs preparation. Tours represent multi-venue itinerary and base hardware; reusable show programming still needs its own production model. |
| Configurations; configuration detail; template drawing | Replaced by Load Out list and inventory → placement → patch → review. No blank venue drawing. |
| Equipment inventory; equipment detail | Physical unit inventory with stable ID, model, role and ownership; reference-aware removal. Profile binding and bulk serial/quantity entry remain follow-up work. |
| Fixture library; fixture profile | Clearly identified design previews. Production must pin real profile revisions/modes and propagate footprint changes through dependent patches. |
| Venues; create venue; venue overview | Shared available scans plus intake inbox; movie upload; import without show/template; per-venue Load Out list. |
| Venue drawing | Placement schematic with numeric X/Y/Z/yaw controls, linked scan, no invented room boundaries. Actual splat rendering and calibration remain missing. |
| Patch; overrides | Patch is per Load Out; Tour base inventory changes are reviewed here. Legacy programming overrides remain a preview, not a second room configuration. |
| Presets; preset editor | Load Out context required; sample library preview retained. Production needs real fixture/group binding, partial-parameter intent and compatibility checks. |
| Cues; cue editor | Keep cue definition separate from script occurrence; current sample content is labeled. Implement real creation, editing and missing-target handling before release. |
| Scripts; script editor | Existing occurrence IDs, ordering and MIDI/timing controls remain. Preview drafts are isolated per Load Out. Reusable program adoption across Tour stops remains open. |
| Rehearsal; live console | Enter through a Load Out review; output stays simulated. Existing console interactions and pop-out remain design validation surfaces. No “ready” badge claims hardware readiness. |
| Connections; universe monitor; recovery; preflight | Connection/recovery/monitor screens remain explicitly simulated. Core planning checklist is derived. Hardware authorization, bridge state and active-run ownership remain separate production gates. |
| Files & drawings | Scan downloads tied to venues. Supporting document storage remains planned; a drawing cannot create a physical room. |
| Activity & versions | Actual local preparation events with explicit local-only label. No fake server revision restore. Production audit, version conflicts and recovery remain open. |
| Team & access | No-op invite forms removed from active navigation. Requires real roles/tenant enforcement before collaboration. |
| Show settings | Workspace export and future native handoff replace ambiguous show-scoped room settings. No unsupported archive mutation offered. |
| Plan & billing | Actual local entity counts; billing unavailable. No invented prices, limits or payment flow. |
| Standalone movie capture | Minimal upload without Tour/Load Out. Persistent server job, progress, failure/retry and later import remain available. |

## Verified journeys

1. Empty workspace → blocked Load Out creation → inbox → import a processed scan → physical inventory.
2. Independent Load Out → fixture selection → placement → patch → review; alternate Load Out in the same venue remains separate.
3. Tour → base inventory → two stops at the same venue → separate Load Outs → one local addition → unchanged base and other stop.
4. Tour base change → pending review at each existing stop → explicit adoption → removed base unit retained locally with placement/patch.
5. Duplicate Load Out → same physical inventory IDs, separate editable plan, no extra Tour stop.
6. Upload and processing failure → retry with the same venue ID; fresh browser session reads the server record; import without show/template.
7. Workspace navigation and preparation tabs at desktop and 390px phone width; preview routes retain Load Out context.

Screenshots under `tmp/saas-ux-review/` are captured from the real React UI using an isolated browser and a synthetic scan API record. They demonstrate the interface, not successful GPU reconstruction of The Glasshouse. Upload integration tests use a temporary actual intake service with a fixture processor; no GPU jobs are launched by review tests.

## Remaining release gates

1. Render the actual scan in SaaS; validate scale/origin/orientation, version it, and place fixtures against it. A downloadable PLY plus schematic is insufficient for finished spatial UX.
2. Persist workspace inventory, Tours, Load Outs and program revisions in an authenticated tenant service with conflict handling, backup/recovery and permission checks. The new preparation model is local to this browser.
3. Bind inventory to real fixture profiles/modes, support editing and bulk registration, resolve dependencies when units or modes change, and handle concurrent-use scheduling where required.
4. Replace sample programming with production entities and ID-based fixture/group targets. Reusable show programs and Tour adoption must never change a running snapshot silently.
5. Validate bridge pairing/output, runtime snapshots, reconnection and arm/disarm ownership independently of preparation readiness.
6. Implement native Load Out import/sync with shared IDs, scan revision, coordinate convention and explicit conflict resolution in a later release.
7. Conduct keyboard/screen-reader, contrast and touch usability research with venue operators and touring programmers. Browser layout checks are not an accessibility certification.

## Verification record — 2026-10-04

- Production frontend build passed.
- 21 Node model tests passed, including 6 new workspace invariant tests.
- 57 workspace browser checks passed across desktop, phone, all navigation sections, preparation flows and programming preview routes.
- 23 browser checks against the isolated real intake service passed.
- 8 Python intake API tests passed, including import without show/configuration.
- Existing live-console browser checks passed: touch selection, transport, MIDI test calls, hot edits, independent sessions and responsive synchronized pop-out.
- Existing script-slot browser checks passed: mouse/touch drag, keyboard ordering, cancellation, persistence, repeated cue identity and reviewed live updates.
- Screenshots were visually reviewed for overview, Tour, Load Out inventory and phone layout. Browser review uses synthetic scan data; real GPU reconstruction was not exercised.
