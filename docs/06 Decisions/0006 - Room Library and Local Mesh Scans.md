---
type: decision
status: experimental
owner: engineering
updated: 2026-10-01
---

# 0006 — Room library and local mesh scans

Extend the visionOS lighting proof of concept with a local room library and independently named fixture setups. Keep the bundled white classroom as the default. The wrist Toolbox owns environment import/capture, setup save/load, and blank-scene navigation.

## Geometry and setup boundaries

An environment is immutable geometry plus versioned coordinate, spawn, checksum, collision, and placement metadata. Import prepared room bundles or meter-scale USDZ; standalone assets receive inferred floor bounds and should use prepared metadata when accurate placement surfaces matter.

A named setup references one environment version and snapshots fixture identities, patch, transforms, resolved DMX, aim overrides, referenced presets, room-light level, and material mode. Save updates that setup; Save as new creates a separate identity. New blank retains the environment and preserves named saves. Prompt before discarding a changed arrangement. Keep legacy working-arrangement autosave separate, and preserve unreadable files.

Restoring a saved setup must not alter another setup's look through a shared mutable preset. Restore its captured definition; reuse an equivalent existing preset or fork a conflicting identity. This is a prototype snapshot boundary, not the production show's immutable profile publication model.

## Capture and interaction

Use ARKit SceneReconstructionProvider with classification in a mixed immersive capture space. Copy observed MeshAnchor geometry, normalize the classified floor to Y=0, and save mesh chunks plus a spawn pose locally. Store a neutral mesh, not camera textures. Reject unsupported hardware, missing permission/tracking, and insufficient floor coverage. Cap captures at one million triangles and 2,048 chunks.

Replay captured rooms with RealityKit PBR meshes, static mesh targets, and dynamic fixture lighting. This works in Simulator and on device without requiring a live capture session. Saved scans are remote room environments in full immersion; physical-world relocalization is not implemented.

Keep the toolbox above the left wrist while visible and hold its position during dragging. Moving-head and cube rows provide native fixture drag payloads. Surface attachments map drop coordinates to room meters; scan placement samples horizontal mesh beneath the footprint. Existing preset drag/drop, retargeting, and transform controls remain available.

## Validation and limits

34 Core tests, model/session checks, asset integrity checks, Simulator build, and unsigned device build pass. Native Simulator integration exercised bundle import, synthetic mesh replay, fixture insertion, named save, blank setup, and restoration of the original classroom. The synthetic mesh is explicitly test data, not evidence of headset capture.

Live World Sensing capture, native drag gestures, wrist ergonomics, device signing/deployment, and performance remain physical-device acceptance work. Missing scan coverage stays missing; footprint sampling is not a complete collision solver. Data remains local with no export or cloud-backup UI. See the [app README](../../apps/visionos/README.md) for usage and screenshots.
