---
type: feature
id: F10
status: specified
owner: product-and-engineering
updated: 2026-09-19
---

# F10 — DMX presets

## Intent and basis

Confirmed domain. Make repeated fixtures easy to program with reusable DMX parameter presets.

The domain requested by the founder is authoritative. Detailed policies below are proposed requirements pending R&D validation, not evidence of implemented production behavior.

## Data and rules

Entities: Preset, PresetRevision, ParameterSet, TargetSelector, VenuePresetOverride.

Presets hold selected semantic parameters, not an implicit complete frame. Targets may be a role, group, or instance. Capability compatibility is explicit. Venue-specific values adapt an existing show preset. Precedence among multiple overlapping assignments must be deterministic and validated.

## Interface responsibilities

Provide preset grid, creation, parameter editor, target/capability information, intensity/color controls, used-by references, scope selection, and reset-to-show.

Wireframe and high-fidelity screens are mapped in [[../Design/Screen Inventory|Screen Inventory]]. See [[../Design/Interaction Coverage|Interaction Coverage]] for what the prototype actually implements.

## API, storage, and service responsibilities

Version parameter schemas and profile dependencies; return provenance and capability errors. Deletion reports affected cues. Changes affect drafts until publication.

## Runtime and operational responsibilities

Compile resolved presets through venue role/instance mapping. Excluded parameters do not accidentally become zero. Exact assignment priority and mixed-fixture fallbacks require an accepted engine decision.

## Acceptance scenarios

Editing one role preset updates every compatible target in the compiled draft; a venue intensity override affects only that venue; deleting a referenced preset cannot silently break published cues.

Apply tenant isolation, revision conflicts, invalid input, empty/loading/error, and permission checks where relevant. Test against resolved data rather than only the presentation.

## Relationships

- [[Feature Catalog]]
- [[../../03 Engineering/Domain Model|Domain Model]]
- [[../../03 Engineering/Service and Runtime Boundaries|Service and Runtime Boundaries]]
- [[../Design/Screen Inventory|Screen Inventory]]

