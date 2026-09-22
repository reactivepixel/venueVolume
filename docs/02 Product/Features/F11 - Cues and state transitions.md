---
type: feature
id: F11
status: specified
owner: product-and-engineering
updated: 2026-09-19
---

# F11 — Cues and state transitions

## Intent and basis

Confirmed domain. Represent moments as named show states with preset assignments and other configuration.

The domain requested by the founder is authoritative. Detailed policies below are proposed requirements pending R&D validation, not evidence of implemented production behavior.

## Data and rules

Entities: Cue, CueRevision, CueAssignment, TransitionPolicy, VenueCueOverride.

A cue definition exists independently of script order. Activating it resolves venue-specific fixtures and presets. Fade-in/out, interruption, omitted parameters, and entry/exit behavior must be explicit. Additional non-lighting actions are typed extensions and require their own adapter contracts.

## Interface responsibilities

Provide cue list, editor, role-to-preset assignments, timing and notes, resolved preview, usage references, validation, and venue adaptation.

Wireframe and high-fidelity screens are mapped in [[../Design/Screen Inventory|Screen Inventory]]. See [[../Design/Interaction Coverage|Interaction Coverage]] for what the prototype actually implements.

## API, storage, and service responsibilities

Persist references, versioned transition policy, and structured configuration. Reject missing presets or targets. Publish only validated cue graphs/snapshots.

## Runtime and operational responsibilities

Runtime states include disarmed, ready, transitioning, active, held, blackout, and recovery-required. Duplicate activation commands are deduplicated. Direct cue activation is distinct from moving script position.

## Acceptance scenarios

The same cue resolves to different venue fixtures without duplicating the cue; GO triggers exactly once; interruption and release policy produce repeatable results. Initial proposal: non-tracking complete resolved states with explicit release to baseline.

Apply tenant isolation, revision conflicts, invalid input, empty/loading/error, and permission checks where relevant. Test against resolved data rather than only the presentation.

## Relationships

- [[Feature Catalog]]
- [[../../03 Engineering/Domain Model|Domain Model]]
- [[../../03 Engineering/Service and Runtime Boundaries|Service and Runtime Boundaries]]
- [[../Design/Screen Inventory|Screen Inventory]]

