---
type: architecture
status: proposed
owner: engineering
updated: 2026-10-04
---

# Domain Model

The founder's 2026-10-04 clarification replaces the template-first room model. See [[../02 Product/Design/SaaS UX Review - Scanned Venues and Load Outs]]. The product rules are confirmed; service and revision details below are proposed beyond the local implementation.

## Ownership

- **Workspace** owns scanned venues, physical fixture units, Tours, Load Outs, memberships and reusable programming.
- **Venue** identifies a physical room and its processed scan. Its intake may be pending, processing, failed, ready for import or imported. It does not own shared fixture placements.
- **Load Out** references exactly one imported venue scan and selects physical unit IDs. It owns placement, patch and readiness. A venue has any number of Load Outs.
- **Tour** owns a base physical-unit selection and ordered stops. Each stop references a venue and a distinct Load Out. Repeated visits to the same venue have separate stop IDs.
- **Fixture profile** describes a manufacturer/model/mode. A **physical unit** has a stable identity independent of name, placement, patch and model. Duplicate plans do not duplicate units.
- **Programming** defines reusable presets, cues and scripts. A resolved run must name the selected Load Out, scan, program revisions and output mapping. A Tour is not a synonym for a show program.

```text
Workspace → Scanned venues → Load Outs → selected inventory + placement + patch
          → Physical fixtures ↗
          → Tours → base fixture selection → stops → dedicated Load Out per stop
          → Programming → resolved Load Out program → immutable run snapshot
```

## Preparation semantics

Only a ready, imported scan can start a Load Out. Import preserves the original venue UUID, movie and splat; it does not assign a show or rig. No blank areas or CAD-created venues are supported. Drawings are supporting documents.

A Load Out stores a scan reference, base-unit IDs (if touring), additional-unit IDs, per-unit placement and per-unit patch. Coordinates are metres: X right, Y up, Z depth; yaw about Y. Production must pin verified scan scale/origin and immutable scan revision. Current intake has one asset per UUID; revision lineage is not implemented.

A new Tour stop copies the current base selection, with no inherited placement or patch. Existing stops retain their reviewed base until adoption. Local additions affect only the selected Load Out. In the local prototype, removed base units become additions on adoption, preserving placements and patch; removing them subsequently is explicit. A richer production diff may offer exclusion/return choices transactionally.

Removing a placed unit from a Load Out first requires returning it to unplaced inventory. Returning preserves physical identity and patch. A unit referenced by any Tour or Load Out cannot be deleted from workspace inventory. Saved alternative plans do not reserve equipment; simultaneous booking requires a separate availability model.

## Identity, persistence and migration

All production relationships use immutable IDs, never editable labels or array positions. Aggregates need workspace ID, revision, schema version and mutation metadata. Published revisions and active run snapshots must be immutable. Service writes require tenant authorization, optimistic concurrency and transactional reference checks.

The current preparation prototype uses `vv-workspace-v2` in browser storage. It deliberately does not reinterpret old `vv-design-v1` venue/template strings as scanned rooms or physical fixture identities. Old sample data remains untouched. New programming previews use `vv-programming-preview:<loadoutId>` and live sessions use the Load Out ID. They still contain sample programming and are not the production program store.

Movie bytes, pipeline status and splats are persisted by the local intake service. Import sets `setupStatus=configured` with name/city, independently of show/template. Legacy request fields remain compatible but are not part of the new UX. Production cloud storage, tenants and durable preparation records are outstanding.

## Programming and runtime

Preset definitions, cue assignments and script occurrences remain separate identities. Repeated cue occurrences have separate entry IDs. A program binds fixture/group/role IDs to the selected Load Out and validates missing or incompatible targets before compiling.

Inheritance must report the source and revision of each effective value. Explicit zero overrides a default; reset removes the override. A future Tour/program update requires a reviewed diff and cannot move, repatch or reprogram an active snapshot silently.

The simulated console retains manual programmer values, masters, cue transport, MIDI mappings and session history. Active/inspected/selected state remains separate. Structural changes require a validated disarmed transition in production. See [[../02 Product/Features/F18 - Persistent console and live updates]].

## Integrity checks

- Layout refers to an imported processed scan in the authorized workspace.
- Each Load Out references existing units at most once; each Tour stop has its own matching venue/Load Out pair.
- Placement coordinates are finite and use the reviewed scan coordinate convention.
- Patch footprints fit slots 1–512 and do not overlap within a universe.
- Base changes remain pending per Load Out until explicit adoption.
- Production compilation validates profiles, targets, assets, authorization and exact revisions.
- A preparation checklist is not proof of valid hardware output or physical rigging.
