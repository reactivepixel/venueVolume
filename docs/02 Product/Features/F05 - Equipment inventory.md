---
type: feature
id: F05
status: specified
owner: product-and-engineering
updated: 2026-09-19
---

# F05 — Equipment inventory

## Intent and basis

Confirmed domain. Track all show production equipment, including lighting fixtures and non-DMX items.

The domain requested by the founder is authoritative. Detailed policies below are proposed requirements pending R&D validation, not evidence of implemented production behavior.

## Data and rules

Entities: EquipmentDefinition, InventoryLine, FixtureInstance, Ownership, LogicalRole.

Inventory is not limited to lights: audio, rigging, staging, power, cabling, and other items are valid. Quantity line items and independently patched fixture instances are distinct. Repeated fixtures need stable instance IDs and logical roles.

## Interface responsibilities

Provide category/filter/search, quantities, item inspection, ownership/rental notes, template source, venue additions/removals, and placement status.

Wireframe and high-fidelity screens are mapped in [[../Design/Screen Inventory|Screen Inventory]]. See [[../Design/Interaction Coverage|Interaction Coverage]] for what the prototype actually implements.

## API, storage, and service responsibilities

Store parent scope, definition, quantity, instance IDs, profile/mode references where relevant, and override provenance. Non-DMX equipment must not require a DMX address.

## Runtime and operational responsibilities

Only compatible controllable fixture instances reach compilation. Removing equipment requires evaluating cues, groups, placements, and patch references.

## Acceptance scenarios

A 12-cable line item needs no profile; four wash fixtures create four distinct controllable instances; removing a referenced fixture returns a useful dependency report.

Apply tenant isolation, revision conflicts, invalid input, empty/loading/error, and permission checks where relevant. Test against resolved data rather than only the presentation.

## Relationships

- [[Feature Catalog]]
- [[../../03 Engineering/Domain Model|Domain Model]]
- [[../../03 Engineering/Service and Runtime Boundaries|Service and Runtime Boundaries]]
- [[../Design/Screen Inventory|Screen Inventory]]

