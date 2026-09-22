---
type: feature
id: F09
status: specified
owner: product-and-engineering
updated: 2026-09-19
---

# F09 — Inheritance and overrides

## Intent and basis

Confirmed behavior; resolution policy proposed. Define at show level and override at venue level, always exposing the effective source.

The domain requested by the founder is authoritative. Detailed policies below are proposed requirements pending R&D validation, not evidence of implemented production behavior.

## Data and rules

Entities: OverrideRecord, SourceReference, ResolvedValue, RevisionConflict.

An explicit venue value wins over a show default, including zero and false. Missing override means inherit. Reset removes the override. For configuration, template revision is the structural baseline; it is not an additional precedence layer for every preset field. Upstream updates use a three-way comparison.

## Interface responsibilities

Provide show/venue scope switch, inherited/overridden provenance per field, compare view, reset confirmation, revision review, and conflict resolution.

Wireframe and high-fidelity screens are mapped in [[../Design/Screen Inventory|Screen Inventory]]. See [[../Design/Interaction Coverage|Interaction Coverage]] for what the prototype actually implements.

## API, storage, and service responsibilities

Represent changes by entity ID and field path with base revision. Explicit deletes use tombstones; arrays and script order use stable entry IDs and an explicit replacement/reorder policy. Reject stale writes.

## Runtime and operational responsibilities

Produce an immutable fully resolved snapshot before arming. Runtime never depends on a changing chain of cloud lookups.

## Acceptance scenarios

An override of 0 stays 0; resetting it re-exposes a subsequently changed show default; disjoint upstream and local edits merge; conflicting edits require a choice; sibling venues remain isolated.

Apply tenant isolation, revision conflicts, invalid input, empty/loading/error, and permission checks where relevant. Test against resolved data rather than only the presentation.

## Relationships

- [[Feature Catalog]]
- [[../../03 Engineering/Domain Model|Domain Model]]
- [[../../03 Engineering/Service and Runtime Boundaries|Service and Runtime Boundaries]]
- [[../Design/Screen Inventory|Screen Inventory]]

