---
type: feature
id: F06
status: specified
owner: product-and-engineering
updated: 2026-09-19
---

# F06 — Fixture profiles and roles

## Intent and basis

Supporting requirement. Describe fixture capabilities so reusable presets work across repeated and replacement fixtures.

The domain requested by the founder is authoritative. Detailed policies below are proposed requirements pending R&D validation, not evidence of implemented production behavior.

## Data and rules

Entities: FixtureProfile, ProfileRevision, Mode, ChannelDefinition, Capability, FixtureRole, FixtureGroup.

Profiles describe types; instances represent physical units. A mode has a footprint, parameter mapping, coarse/fine channels, ranges, units, and explicit safe defaults. Profile revision is pinned. Manufacturer control ranges must not receive arbitrary normalized values.

## Interface responsibilities

Provide profile search, mode/channel inspection, custom profile flow, unverified badges, incompatibility feedback, and role/group selection.

Wireframe and high-fidelity screens are mapped in [[../Design/Screen Inventory|Screen Inventory]]. See [[../Design/Interaction Coverage|Interaction Coverage]] for what the prototype actually implements.

## API, storage, and service responsibilities

Import schemas need validation, provenance, licensing, versioning, and content hashes. Bind logical roles to stable venue instances; reject ambiguous or unsupported mappings.

## Runtime and operational responsibilities

Compile semantic intensity/color/position into validated channel mappings. Missing required capabilities block arming unless an explicitly reviewed fallback exists.

## Acceptance scenarios

One intensity preset resolves across four compatible washes; a replacement with a different mode receives its own correct mapping; unsupported color capability produces an actionable error.

Apply tenant isolation, revision conflicts, invalid input, empty/loading/error, and permission checks where relevant. Test against resolved data rather than only the presentation.

## Relationships

- [[Feature Catalog]]
- [[../../03 Engineering/Domain Model|Domain Model]]
- [[../../03 Engineering/Service and Runtime Boundaries|Service and Runtime Boundaries]]
- [[../Design/Screen Inventory|Screen Inventory]]

