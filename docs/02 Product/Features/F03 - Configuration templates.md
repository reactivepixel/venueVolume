---
type: feature
id: F03
status: specified
owner: product-and-engineering
updated: 2026-09-19
---

# F03 — Configuration templates

## Intent and basis

Confirmed domain. Maintain multiple reusable configurations inside a show, each with a saved drawing and equipment inventory.

The domain requested by the founder is authoritative. Detailed policies below are proposed requirements pending R&D validation, not evidence of implemented production behavior.

## Data and rules

Entities: ConfigurationTemplate, TemplateRevision, TemplateEquipment, TemplateDrawingReference.

A template is scoped to its show. Publish immutable revisions containing both drawing and inventory references. A venue starts from one exact template revision. Later template changes require explicit review and adoption; this pinning policy is a design proposal.

## Interface responsibilities

Provide template list, creation dialog, details, duplicate flow, linked venues, and drawing/inventory tabs. Expose revision and adoption status.

Wireframe and high-fidelity screens are mapped in [[../Design/Screen Inventory|Screen Inventory]]. See [[../Design/Interaction Coverage|Interaction Coverage]] for what the prototype actually implements.

## API, storage, and service responsibilities

Store revision lineage and stable equipment keys. Validate drawing placements against inventory. Template deletion reports downstream use and never orphans venues.

## Runtime and operational responsibilities

Compile from the venue's pinned template revision. Template publication has no immediate output side effect.

## Acceptance scenarios

Two venues starting from one template can diverge independently; a new template revision does not silently move or repatch fixtures at either venue.

Apply tenant isolation, revision conflicts, invalid input, empty/loading/error, and permission checks where relevant. Test against resolved data rather than only the presentation.

## Relationships

- [[Feature Catalog]]
- [[../../03 Engineering/Domain Model|Domain Model]]
- [[../../03 Engineering/Service and Runtime Boundaries|Service and Runtime Boundaries]]
- [[../Design/Screen Inventory|Screen Inventory]]

