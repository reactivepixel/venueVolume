---
type: decision
status: experimental
owner: engineering
updated: 2026-10-01
---

# 0005 — Mesh room lighting proof of concept

The visionOS proof of concept combines the palm toolbox/preset workflow with the current reconstructed classroom and a catalog moving-head asset. It uses the GitHub dev research baseline at `619f0d7` and the earlier spatial prototype at `e29e107`.

## Evidence and choice

The current [movie workflow](../05%20Operations/mov2splat-review.md) exports an opaque USDZ mesh with validated environment/interaction metadata. It is separate from the optional movie-to-Gaussian pipeline. Use the existing mesh directly for dynamic lighting, depth occlusion, and cast shadows on Simulator and visionOS 2+; do not require visionOS 27 Gaussian rendering or claim automatic splat meshing.

The working room assumption is the IMG_3153 classroom. A reversible White model material override supplies the neutral lighting-study view without changing source assets. Full immersion displays a remote reconstructed room; physical room registration is outside this spike.

The catalog Rogue R1X Spot proxy supplies editable Base/Yoke/Head transforms and an emitter. Reparent Head under Yoke with its rest pose preserved. Drive these pivots and a shadowed RealityKit spotlight from a documented synthetic 16-channel preview personality. Manufacturer channel mappings are untranscribed, so this must not become a hardware personality. RGB and beam zoom in the preview are not claims about the manufacturer's optical capabilities.

## State boundaries

- Fixture instances retain room-local base position/yaw, patch, asset identity, and optional saved-preset assignment.
- Preset edits remain drafts; optional temporary preview affects only the selected fixture's rendering. Saving updates assigned fixtures; Save as New preserves prior assignments.
- Blackout is a temporary renderer override. Room light and original/white materials remain independent of presets.
- Persist placements by room version, including resolved values and asset IDs; retain compatibility with existing cube saves.
- Keep the left-palm Toolbox, ten Recent items, read-only object Info, and separate preset editor. Add a Fixture position tab to that editor.

## Proof and limits

26 Core tests, session/model checks, asset hashes, Simulator build, and unsigned device build passed with Xcode 27. Simulator renders show blue/warm response, articulated pan, a speaker casting a shadow on the wall, and blackout. The locked Mac prevented interactive UI automation. No physical Vision Pro was connected, so signing/deployment, palm behavior, tracked placement and headset performance remain unverified.

This is direct-light previsualization with estimated geometry, a maximum of four new moving-head fixtures, no calibrated photometry/indirect bounce/volumetric haze, and no physical DMX output. Manual transforms enforce room bounds but do not prevent furniture intersection. Colliders do not prevent a wearer from walking through geometry. This is not the production domain's immutable profile/preset publication or runtime arming system.

See the [application README](../../apps/visionos/README.md) for the exact profile, run instructions, screenshots, and acceptance work.
