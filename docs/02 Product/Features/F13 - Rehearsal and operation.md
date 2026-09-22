---
type: feature
id: F13
status: specified
owner: product-and-engineering
updated: 2026-09-19
---

# F13 — Rehearsal and operation

## Intent and basis

Supporting requirement. Rehearse a resolved show and run it with clear current/next state, preflight, ownership, hold, and blackout.

The domain requested by the founder is authoritative. Detailed policies below are proposed requirements pending R&D validation, not evidence of implemented production behavior.

## Data and rules

Entities: RunSnapshot, RunSession, OutputLease, OperatorCommand, CommandAcknowledgement.

Separate rehearsal preview from armed physical output. A run pins show/venue/script/profile revisions. One authorized owner controls an output session. Editor saves never mutate a running snapshot. Blackout is a latched output modifier; restore is explicit.

## Interface responsibilities

The confirmed revision adds desk-style live programming and a detached touch console. See [[F16 - Workflow modes and live programmer]], [[F17 - Script transport and MIDI triggers]], and [[F18 - Persistent console and live updates]] for selection, temporary overrides, masters, MIDI, restart, and explicit no-reload runtime updates. Draft saves remain separate from applying edits to a running revision.

Provide rehearsal, live console, preflight, current/next cue, armed state, master controls, command acknowledgement, freshness, disconnect, and recovery. Never use color alone for status.

Wireframe and high-fidelity screens are mapped in [[../Design/Screen Inventory|Screen Inventory]]. See [[../Design/Interaction Coverage|Interaction Coverage]] for what the prototype actually implements.

## API, storage, and service responsibilities

Authorize commands, validate session/revision/sequence, use idempotency keys, record acknowledgements and an audit trail. Control leases must have defined expiry/failover semantics.

## Runtime and operational responsibilities

The bridge applies commands and evaluates transitions locally. Hold pauses defined progression; blackout suppresses defined intensity outputs without assuming arbitrary control-channel values are safe. Test emergency behavior against real fixtures.

## Acceptance scenarios

Invalid patch blocks arming; hold/blackout/disconnect prevents unintended GO; only acknowledged state is shown as actual; a second operator cannot seize output without explicit transfer; UI reload does not replay commands.

Apply tenant isolation, revision conflicts, invalid input, empty/loading/error, and permission checks where relevant. Test against resolved data rather than only the presentation.

## Relationships

- [[Feature Catalog]]
- [[../../03 Engineering/Domain Model|Domain Model]]
- [[../../03 Engineering/Service and Runtime Boundaries|Service and Runtime Boundaries]]
- [[../Design/Screen Inventory|Screen Inventory]]
