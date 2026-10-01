---
type: map
status: active
owner: product-and-engineering
updated: 2026-09-30
---

# Fixture library

The fixture library is the reusable hardware reference and 3D asset collection for Venue
Volume. A record describes one manufacturer/model/variant, independently of a particular
venue, physical inventory unit, DMX start address or show. Productions should eventually
pin both its stable ID and revision.

## Browse and create

- [Fixture catalog](Catalog.md) — all entries and their research/model status.
- [Machine catalog](../../assets/fixtures/catalog.json) — metadata for future library tooling.
- [Create Venue Fixture skill](skill/create-venue-fixture/SKILL.md) — canonical copy of the skill.
- [Record contract](skill/create-venue-fixture/references/record-contract.md).
- [Modeling and validation guide](skill/create-venue-fixture/references/modeling.md).

Invoke the installed skill with an exact physical product:

```text
Use $create-venue-fixture to add [manufacturer] [model number] to the Venue Volume
fixture library. Research the official product page, drawings and DMX manual, then
build and validate the scaled Blender/USDZ model and update the library documentation.
```

If it is not installed on another machine, point the agent directly to the linked SKILL.md,
or copy the complete `create-venue-fixture` directory into `~/.codex/skills/`. Keep the
installed directory and this canonical copy synchronized when editing the workflow.

## What each entry contains

| Area | Contents |
| --- | --- |
| Identity | Manufacturer, exact model/variant, aliases and revision |
| Evidence | Manufacturer URLs, document versions/pages, local reference assets and hashes |
| Specifications | Dimensions and pose, optical/electrical/mechanical/control facts with units and sources |
| DMX | Named modes, footprints, applicable firmware and documented channel behavior |
| Authoring | Editable Blender model and reproducible generator or CAD-conversion script |
| Runtime | Meter-scaled Y-up USDZ, stable part hierarchy, joint pivots and light-emitter anchors |
| Review | Four preview angles, bounds checks, approximation notes and actual test status |

`assets/fixtures/<manufacturer>/<model-variant>/fixture.json` is the machine record.
Its linked note under `entries/` summarizes the research and exposes models/previews.
Unknown dimensions or capabilities remain unknown; a draft is useful but cannot be labeled
ready for visualization. Known outer dimensions do not make every modeled detail precise.

## Lighting and application use

Use relightable materials for the fixture body and a separate lens/emitter anchor for
future artificial lighting. Preserve sourced zoom, beam/field angles, color capabilities
and gobo information as data. A luminous-looking lens does not itself illuminate a room;
adding RealityKit lights and mapping DMX values to them is separate runtime work.

This milestone supplies the research/modeling skill and library contract. It does not add
an app library picker, manufacturer profile importer, remote asset service, DMX compiler,
or live hardware output. The existing Swift app still uses generic fixture cubes.
The library now includes source-backed manufacturer records, editable Blender models,
full-detail USDZ files and rendered previews. Browse the
[show equipment hierarchy](Show%20Equipment%20Hierarchy.md) for category coverage and
remaining gaps, or the [visual explorer](../../assets/fixtures/research/show-equipment.html).
The historical `assets/fixtures/` path now also holds atmosphere, visual effects and
support-equipment records. Passive objects and effect outlets are not light emitters.

## Evidence and update rules

- `draft`: identification, evidence or geometry is incomplete.
- `researched`: useful sourced specifications are recorded; runtime model may be incomplete.
- `ready_for_visualization`: the scaled package passes validation with supporting artifacts.
- Physical DMX verification and RealityKit testing are recorded separately from those statuses.

Keep source images/manuals separate from distributable models and record reuse terms.
Preserve hand edits and previous revisions when updating an existing model. Rebuild the
catalog from validated records so duplicate variants and missing files are visible.

Related: [[../02 Product/Features/F06 - Fixture profiles and roles|Fixture profiles and roles]],
[[../02 Product/Features/F05 - Equipment inventory|Equipment inventory]], and
[[../03 Engineering/Domain Model|Domain model]].
