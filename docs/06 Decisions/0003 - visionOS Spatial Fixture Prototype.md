---
type: decision
status: accepted
owner: engineering
updated: 2026-09-22
---

# 0003 — visionOS Spatial Fixture Prototype

## Context

The requested prototype places transparent cubes in the user's space, configures them as DMX fixtures with up to 16 controls, and syncs all configurations through a mock request. It belongs in `apps/`, separate from the web design studio and physical output runtime.

## Decision

Implement `apps/visionos` as a native visionOS 2+ SwiftUI application with a mixed immersive RealityKit scene. A system-targeted spatial tap places a cube at the gaze-selected point on a visible placement grid. ARKit world tracking supplies the device pose to position the grid at a configurable distance. Raw gaze is unavailable to applications. A continuous head anchor carries the debug panel; fixture labels and inspectors use world-space attachments facing the wearer.

Generic fixtures have stable instance UUIDs, logical universe, one-based start address, and 1–16 unsigned 8-bit channel values. Atomic patch updates reject out-of-range footprints and same-universe collisions. New fixtures receive an available patch. These instance controls are an R&D subset, not a replacement for the canonical show/venue/profile model.

Keep validation and mock transport in a local, dependency-free Swift package, testable on macOS. Sync captures the complete applied configuration at one revision and makes a URLSession POST intercepted by a local URLProtocol. It sends no network traffic or physical DMX. Later edits cannot accidentally mark themselves as synced by an earlier response.

## Consequences

- No backend, bridge, room-mesh permission flow, or manufacturer fixture library is needed to run the experiment.
- Simulator uses a fixed placement grid because ARKit device pose is unavailable there; physical interaction and comfort require headset verification.
- State and coordinates are session-only. Persisted room anchors, profile semantics, service authentication, and show/venue integration remain future work.
- The request/response envelope can be inspected without silently implying a live lighting connection.
