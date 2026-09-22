---
type: feature
id: F02
status: specified
owner: product-and-engineering
updated: 2026-09-19
---

# F02 — Show lifecycle

## Intent and basis

Confirmed domain. Create a project called a show, maintain its defaults, and manage the production lifecycle.

The domain requested by the founder is authoritative. Detailed policies below are proposed requirements pending R&D validation, not evidence of implemented production behavior.

## Data and rules

Entities: Show, ShowRevision, ShowSettings, ArchiveRecord.

A show owns templates, venues, presets, cues, scripts, and asset references. IDs are stable across renames. Archive is recoverable and blocked while an output session is active. Duplication must remap internal references without sharing mutable ownership.

## Interface responsibilities

Provide show list, creation, overview, settings, duplication review, empty/error states, and export. Make the current show and unsaved state visible.

Wireframe and high-fidelity screens are mapped in [[../Design/Screen Inventory|Screen Inventory]]. See [[../Design/Interaction Coverage|Interaction Coverage]] for what the prototype actually implements.

## API, storage, and service responsibilities

Use revision-based writes, tenant-scoped queries, transactional reference validation, versioned exports, and paginated listing. Published revisions are immutable snapshots.

## Runtime and operational responsibilities

Runtime pins a published show revision; cloud edits produce a draft. Archiving or deleting must not invalidate a running revision or retained evidence.

## Acceptance scenarios

Renaming preserves cue/script references; restoring an older revision creates a new draft; an export round-trip preserves IDs or an explicit import remapping table.

Apply tenant isolation, revision conflicts, invalid input, empty/loading/error, and permission checks where relevant. Test against resolved data rather than only the presentation.

## Relationships

- [[Feature Catalog]]
- [[../../03 Engineering/Domain Model|Domain Model]]
- [[../../03 Engineering/Service and Runtime Boundaries|Service and Runtime Boundaries]]
- [[../Design/Screen Inventory|Screen Inventory]]

