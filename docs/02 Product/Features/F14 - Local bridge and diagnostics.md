---
type: feature
id: F14
status: specified
owner: product-and-engineering
updated: 2026-09-19
---

# F14 — Local bridge and diagnostics

## Intent and basis

Proposed architecture required for venue output. Connect SaaS planning to venue-local DMX/Art-Net output, with telemetry and recovery.

The domain requested by the founder is authoritative. Detailed policies below are proposed requirements pending R&D validation, not evidence of implemented production behavior.

## Data and rules

Entities: BridgeRegistration, PairingGrant, BridgeSession, OutputConfig, TelemetrySnapshot, RecoveryRecord.

Use a paired venue-local process/device for network transport and timing. Ordinary browser UI APIs do not provide the raw Art-Net UDP output path. The exact packaging, supported OS, USB adapters, and offline credential policy need R&D decisions.

## Interface responsibilities

Provide pairing, connection list, interface/destination settings, routing, 512-slot universe monitor, telemetry timestamps, ownership and explicit reconnect review.

Wireframe and high-fidelity screens are mapped in [[../Design/Screen Inventory|Screen Inventory]]. See [[../Design/Interaction Coverage|Interaction Coverage]] for what the prototype actually implements.

## API, storage, and service responsibilities

Pairing uses short-lived grants and authenticated channels; do not expose an unauthenticated LAN command socket. Store bridge identity, grants, health and published bundles. Separate cloud availability from local bridge availability.

## Runtime and operational responsibilities

The bridge also owns MIDI input normalization/deduplication, restart generations, programmer evaluation, and run continuity across browser windows. Web MIDI and same-origin pop-out coordination are prototype affordances. See [[F17 - Script transport and MIDI triggers]] and [[F18 - Persistent console and live updates]].

Run from a validated local immutable bundle. On cloud loss, follow documented local policy; on browser/bridge loss, show stale/unknown state. Recover by querying the bridge's revision, active cue, and ownership before re-arming.

## Acceptance scenarios

Cloud outage does not require frame timing over the internet; stale telemetry is never shown as live; reconnect does not replay GO; network destinations and protocol addresses are validated and protocol compliance is tested.

Apply tenant isolation, revision conflicts, invalid input, empty/loading/error, and permission checks where relevant. Test against resolved data rather than only the presentation.

## Relationships

- [[Feature Catalog]]
- [[../../03 Engineering/Domain Model|Domain Model]]
- [[../../03 Engineering/Service and Runtime Boundaries|Service and Runtime Boundaries]]
- [[../Design/Screen Inventory|Screen Inventory]]
