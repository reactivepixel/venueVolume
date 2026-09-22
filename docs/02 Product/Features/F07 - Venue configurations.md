---
type: feature
id: F07
status: specified
owner: product-and-engineering
updated: 2026-09-19
---

# F07 — Venue configurations

## Intent and basis

Confirmed domain. Give a show any number of venues, starting from a configuration template and adapting locally.

The domain requested by the founder is authoritative. Detailed policies below are proposed requirements pending R&D validation, not evidence of implemented production behavior.

## Data and rules

Entities: Venue, VenueRevision, TemplatePin, VenueEquipmentDelta, VenueDrawingOverride, RoleBinding.

Each venue belongs to one show and pins a template revision. A venue can change layout, inventory, patch, preset values, cue assignments, and script sequencing. The product imposes no fixed conceptual venue count; service limits, if any, require an explicit commercial decision.

## Interface responsibilities

Provide venue list, creation with template/revision selection, venue overview, drawing, patch, readiness, and inherited/local badges.

Wireframe and high-fidelity screens are mapped in [[../Design/Screen Inventory|Screen Inventory]]. See [[../Design/Interaction Coverage|Interaction Coverage]] for what the prototype actually implements.

## API, storage, and service responsibilities

Store local changes separately from inherited sources. Use stable IDs and transactional venue creation. Rebase/adopt operations preview conflicts and preserve removals via tombstones.

## Runtime and operational responsibilities

A run identifies show ID, venue ID, resolved revision, role map, and output routing. Switching venues is an explicit stop/recompile/re-arm operation.

## Acceptance scenarios

A venue addition does not modify the show template; renaming a venue preserves its references; switching venue context cannot leak one venue's overrides into another.

Apply tenant isolation, revision conflicts, invalid input, empty/loading/error, and permission checks where relevant. Test against resolved data rather than only the presentation.

## Relationships

- [[Feature Catalog]]
- [[../../03 Engineering/Domain Model|Domain Model]]
- [[../../03 Engineering/Service and Runtime Boundaries|Service and Runtime Boundaries]]
- [[../Design/Screen Inventory|Screen Inventory]]

