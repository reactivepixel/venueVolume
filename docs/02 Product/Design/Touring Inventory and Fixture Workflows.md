---
type: implementation-plan
status: planned
owner: product-and-engineering
updated: 2026-10-03
---

# Touring Inventory and Fixture Workflows

Build the rig once, then adapt it at each venue. A reusable show carries equipment identities, named fixture groups, presets and focus targets. Each venue setup stores its room, fixture placement, patch and local programming adjustments. The purpose of this plan is to reduce repeated searching, placement and programming while preserving predictable edits and Undo.

The requested direction is persistent touring inventory, hierarchical groups, and presets that can be applied to individuals or all members of a group. The workflow and resolution policies below are the proposed implementation design. This document does not claim these features are implemented. The native baseline is v0.2.4; the web design study already illustrates parts of the broader show model.

## Relationship to the existing product

Follow the accepted [[../../06 Decisions/0002 - Show and Venue Product Domain|show and venue domain]] and the proposed [[../../03 Engineering/Domain Model|revision and override model]]. A configuration template contains reusable drawing/layout and inventory references. Groups and programming belong to the show and resolve against the equipment included in the selected configuration. A room environment is geometry; it can support multiple independently saved venue setups.

| Travels with the show | Belongs to a venue setup |
| --- | --- |
| Equipment identities, models and configuration quantities | Room geometry and its version |
| Named group hierarchy and membership | Fixture positions and mounting orientations |
| Preset library, including unused presets | Venue patch and local equipment additions/exclusions |
| Named focus targets such as Lead vocal | Locations of those targets in the room |
| Configuration templates and optional relative layouts | Explicit venue overrides and pinned source revisions |

The native app currently creates a new `Fixture` identity during placement, maintains one selected fixture, and stores presets as complete arrays of 1–16 channel values. Its saved setups include referenced presets rather than an entire show. Inventory, persistent groups, multi-selection and semantic partial presets need new model and persistence support; they cannot be implemented as palette filters alone.

## Prepare the touring inventory

Create a configuration such as Tour rig by selecting equipment models and quantities. Four Rogue R1X Spots create four distinct controllable units, initially named Spot 01 through Spot 04. Every unit has a stable ID independent of its editable name, room position and patch. Optional physical asset labels can identify real hardware; names must never serve as database keys.

Default the wrist library to the selected configuration's equipment. A row displays model, placed count and available count, for example **Rogue R1X · 2 placed · 2 available**. The complete catalog lives behind **Add equipment**. Non-DMX equipment remains valid inventory and does not require a DMX address; quantity-only consumables and individually controlled fixtures remain distinct.

The fixture profile and selected mode define its DMX footprint. Retain preferred tour patch assignments with the configuration, validate them against venue equipment and offer explicit batch auto-patching for conflicts. Preset edits must not change a fixture's footprint or silently repatch it.

Availability is calculated within the active venue setup. Previously saved venues are alternative configurations and do not reserve the touring hardware forever. Distinguish placed, unplaced, excluded at this venue, and unavailable units. Do not place the same unit twice in one setup or manufacture extra units through Duplicate.

**Return to inventory** removes a placement but preserves the equipment identity, group membership and programming. **Remove equipment from show** is a separate operation that reports dependencies. Reducing a quantity below referenced units requires resolving the affected placements and assignments, rather than silently deleting them. Venue-only equipment is clearly marked and does not change the touring configuration.

## Start a venue with the same equipment

Use **Choose show → Choose venue → Choose configuration**, remembering the current show and configuration. Recent saves restore that complete context. The wrist menu's New venue action uses the same flow.

Offer two layout choices:

- **Blank layout:** retain inventory, groups and presets; leave equipment unplaced.
- **Adapt previous layout:** preview the prior arrangement against the selected room, align its reference frame and review positions before committing.

Loading another room must not overwrite the shared inventory or silently replace a different show. All three bundled environments and locally imported/scanned rooms use this flow. Missing assets or incompatible imported data produce a recoverable error while preserving the current setup.

## Place fixtures with fewer repeated actions

**Place remaining** selects a model once and lets successive surface pinches place its available units. Show the next unit's name, remaining count and a Done action. Stop when inventory is exhausted. Keep ordinary one-at-a-time placement and dragging available.

For repeated arrangements, offer **Place group**, **Evenly spaced row** and **Mirror arrangement**. Preview positions, unit identities and quantity before acceptance. Validate all placements and commit the accepted arrangement as one Undo step. Cancelling leaves inventory and placements unchanged.

Repeated placement retains the selected group, appropriate mounting orientation and effective preset assignment. Reuse units already assigned to a group instead of creating replacement identities. Surface validation remains explicit; a scanned horizontal surface does not establish support for arbitrary overhead rigging. Group placement and pattern spacing move fixtures without scaling their physical models.

## Position mounts and focus beams

Keep three distinct actions:

| Action | Changes | Preserves |
| --- | --- | --- |
| Move | Mount position | Orientation, patch and preset intent |
| Rotate mount | Physical mounting orientation | Unit identity, patch and preset intent |
| Focus | Articulation calculated for the preset target | Mount transform and unrelated preset parameters |

A group can move or rotate together while preserving relative offsets. Add alignment, equal spacing and numeric position entry alongside circular rotation and translation controls. Show the active axes and group pivot. A group gesture is one Undo operation.

Create show-level named focus targets such as Lead vocal, Drums and Audience centre. Locate each target once in each venue. Solving a shared target must calculate angles separately for every fixture using its mount transform, authored optical axis and supported articulation. Copying one unit's Pan/Tilt values to differently placed units does not produce convergence.

Focus remains an explicit preview followed by Save or Cancel. Moving a mount does not silently create continuous target tracking; provide Refocus when a saved semantic target needs recalculation. Missing target locations, unsupported articulation or unreachable positions must be visible before committing a group result.

## Build hierarchical fixture groups

Store named groups with stable IDs, a parent group reference and inventory-member references. The initial proposal uses one parent per group and one primary group location per fixture, with an Ungrouped collection for the remainder. Prevent cycles. Overlapping selection sets are deferred so the initial inheritance behavior stays understandable.

```text
All fixtures
├── Front light
│   ├── Stage left
│   └── Stage right
└── Upstage
    ├── Moving heads
    └── Washes
```

Selecting a parent selects its descendant fixtures. Resolve and deduplicate IDs before a command. The wrist inspector shows the group name, selected count, placement status and shared or mixed values. Group rename and reparenting preserve references. Groups survive when all members are unplaced or excluded from a particular configuration.

Deleting a group offers to ungroup its contents while keeping equipment. Adding or removing members previews any resulting inherited preset changes. Selection alone never applies a preset or changes output.

## Build presets from explicit parameters

Extend presets to hold included semantic parameters rather than assuming every preset replaces a complete frame. Start with Intensity, Colour, Beam and Focus categories, plus combined looks. Applying Colour leaves focus and intensity unchanged. Applying Focus leaves colour unchanged. Unspecified values remain untouched; explicit zero is a value rather than an instruction to inherit.

The editor names its target fixture/group, included parameters, compatibility and affected count. Simulation remains enabled by default and stays transient until Save or Apply. Keep one editor window and preserve dirty-draft handling when the selected context changes. Raw channels remain an advanced view for supported profiles.

Saving a shared preset describes its scope, such as **Update Warm wash — used by 8 fixtures**. Save as new creates an independent identity. Show edits update the show draft; venue edits create visible local overrides. An existing saved venue does not silently adopt a newer revision.

The first native implementation may restrict presets to the known VV preview personality. Do not imply that its synthetic 16 channels provide manufacturer-correct behavior across the catalog. General mixed-fixture application depends on explicit profile/capability mapping.

## Apply presets to fixtures and groups

Use **select target → choose preset → Apply** as the primary quick path. Retain spatial dragging with a dotted tether, a solid proposed destination and text/icon success or failure feedback. A group row is also an explicit destination; being spatially near one group member must not silently expand an individual drop to the entire group.

Preview all affected fixtures and name the action, for example **Apply to all 8 fixtures**. Validate the complete target set before publication. Incompatibility blocks the operation with an affected-member list. Applying to only compatible fixtures must be an explicit choice, never silent skipping. One group application creates one history entry with the exact affected identities.

Store group defaults so unplaced units and newly added members can inherit the group's programming. Display individual exceptions as **Overrides group**, with **Reset to group**. Proposed per-parameter precedence within the active venue is an explicit individual assignment, then its closest ancestor group assignment, then the show baseline. Venue overrides adapt the relevant inherited values without writing into the show source.

Distinguish two actions:

- **Edit group default** preserves explicit child-group and individual exceptions.
- **Apply to all descendants** replaces conflicting exceptions for the preset's included parameters and retains unrelated parameters. The preview identifies affected exceptions before acceptance.

Reparenting, local membership changes and later source revisions must show the resulting effective values. These rules cover stored programming and simulation; live cue/programmer priority remains governed by the separate runtime design.

## Save and reuse across venues

Save the show library independently of a room. It includes inventory/configurations, groups, presets and named focus definitions. Each venue setup pins the revisions it used and stores placement, patch, target locations and local overrides. Exporting a reusable show should not require every room asset; exporting a complete venue setup includes the dependencies needed to reopen it.

New configuration revisions use **Review changes** before adoption. Existing completed venue setups remain reproducible. Show and venue scope is visible in every editor; Reset to show removes an override rather than writing a copy of the current default.

Group placement, bulk application, membership changes and revision adoption are atomic audit operations. Undo/Redo restores committed identities and resolved state rather than rerunning a selector against today's membership. Failed or cancelled operations do not leave partial inventory, patch, group or preset changes.

## Native implementation sequence

| Phase | Deliverable | Acceptance gate |
| --- | --- | --- |
| Foundation | Stable inventory units, configuration quantities, venue placements, migration and persistence | One rig loads in multiple rooms without duplicating units or leaking venue changes |
| Groups and application | Multi-selection, named hierarchy, exact target resolution and atomic group application | Nested selection, incompatible-target failure and one-step Undo/Redo pass |
| Preset semantics | Included parameters, effective-source display, group defaults and individual exceptions | Colour preserves focus; parent edits preserve exceptions; Apply to all replaces only the intended parameters |
| Placement speed | Place remaining, group transforms, rows, mirroring and numeric adjustments | Quantity limits, cancellation, geometry validation and grouped history pass |
| Touring focus | Named venue targets, per-fixture solving and explicit refocus | Differently mounted fixtures converge within supported limits; unreachable targets are reported |
| Portability and adoption | Show export/import, pinned revisions and reviewed adoption | Round trip retains unused presets, unplaced members and historical venue setups |

Legacy migration must preserve current saves and recorded history. Existing fixture IDs can become equipment-unit IDs within an imported legacy setup; matching names or models across unrelated saves are insufficient evidence that they represent the same physical unit. Provide explicit mapping when consolidating those saves into one touring rig. Keep full-array legacy presets readable and do not silently reinterpret them as partial semantic presets.

## Acceptance walkthrough and measurement

Use a representative rig of four spots and eight washes. Create Front light with Stage left/Stage right children and an Upstage group. Build a colour preset and a focus preset, then exercise these steps in the neutral classroom, mapped classroom and Fortress:

1. Load the same configuration into a blank venue; confirm all unit IDs, groups and presets are present and unplaced.
2. Place remaining spots; verify the available count reaches zero and a fifth spot cannot be created accidentally.
3. Place and move a wash group; cancel a preview, then accept and Undo/Redo the entire arrangement.
4. Apply colour to a parent group; verify every compatible descendant and preserve unrelated focus/intensity values.
5. Set an individual exception; edit the parent default, reset the exception, and explicitly Apply to all descendants.
6. Save/reopen the venue and export/import the show, retaining unplaced units and unused presets.
7. Start the next room with the same rig, locate named targets and refocus; reopen the first venue and verify its saved configuration is unchanged.
8. Exercise duplicate IDs, invalid hierarchy/cycles, quantity reduction, incompatible profiles, unreachable focus, corrupt imports and interrupted saves without partial publication.

Measure time to first placed fixture, time to complete a repeated group, library returns/reselections, time to build and apply a look, next-venue adaptation time, and errors requiring recovery. Compare with the existing one-fixture workflow on the same rig. Do not publish a setup-time improvement percentage until measured. Simulator checks cover deterministic state and geometry; worn-headset tests cover indirect pinch, accessibility, comfort and actual task time.

## Vision Pro interaction guidance

Use normal movable windows and standard indirect gestures. Every spatial drag also has a selection-and-button route. Keep the wrist reveal optional through an explicit open/recall control. Avoid adding one window per group; reuse the contextual inspector and single preset editor. Scope, selection, applied state and errors use text as well as colour.

These choices follow Apple's [spatial layout](https://developer.apple.com/design/human-interface-guidelines/spatial-layout/), [gestures](https://developer.apple.com/design/human-interface-guidelines/gestures), and [drag and drop](https://developer.apple.com/design/human-interface-guidelines/drag-and-drop) guidance. They still require validation on a worn headset. Physical DMX transport, calibrated manufacturer profiles, simultaneous rental reservations, cloud collaboration and overlapping selection-set semantics remain outside this implementation plan.

## Related requirements

- [[../Features/F03 - Configuration templates|Configuration templates]]
- [[../Features/F05 - Equipment inventory|Equipment inventory]]
- [[../Features/F07 - Venue configurations|Venue configurations]]
- [[../Features/F09 - Inheritance and overrides|Inheritance and overrides]]
- [[../Features/F10 - DMX presets|DMX presets]]
- [[../Features/F15 - History synchronization and portability|History and portability]]
- [Current native app behavior](../../../apps/visionos/README.md)
