---
type: feature
id: F08
status: specified
owner: product-and-engineering
updated: 2026-09-19
---

# F08 — Patch and routing

## Intent and basis

Supporting DMX requirement. Map venue fixture instances to logical universes and concrete DMX addresses.

The domain requested by the founder is authoritative. Detailed policies below are proposed requirements pending R&D validation, not evidence of implemented production behavior.

## Data and rules

Entities: PatchAssignment, LogicalUniverse, OutputRoute, NetworkDestination.

DMX user-facing start addresses use 1–512 and the full footprint must fit. Assignments cannot overlap in the same output universe without a separately designed merge policy. A logical universe label is separate from the protocol wire address.

## Interface responsibilities

Provide editable patch table, footprint preview, conflict messages, universe occupancy, routing details, and inspectable protocol addressing.

Wireframe and high-fidelity screens are mapped in [[../Design/Screen Inventory|Screen Inventory]]. See [[../Design/Interaction Coverage|Interaction Coverage]] for what the prototype actually implements.

## API, storage, and service responsibilities

Validate integer addresses, bounds, overlaps, mode changes, duplicate bindings, and routing collisions server-side and during local compilation. Version patch changes with the venue.

## Runtime and operational responsibilities

Translate logical universe to validated Art-Net route and frame generation. Protocol scheduling and physical transport belong to the local bridge. Frame timing targets remain experimental.

## Acceptance scenarios

An 8-slot fixture at 509 is rejected; fixtures at 1 and 5 overlap; equal addresses in different logical universes do not overlap; the UI's Universe 1 can explicitly route to Art-Net 0:0:0.

Apply tenant isolation, revision conflicts, invalid input, empty/loading/error, and permission checks where relevant. Test against resolved data rather than only the presentation.

## Relationships

- [[Feature Catalog]]
- [[../../03 Engineering/Domain Model|Domain Model]]
- [[../../03 Engineering/Service and Runtime Boundaries|Service and Runtime Boundaries]]
- [[../Design/Screen Inventory|Screen Inventory]]

