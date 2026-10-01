---
type: decision
status: accepted
owner: engineering
updated: 2026-09-25
---

# 0004 — Palm Toolbox and Preset Driven Fixtures

## Context

The visionOS prototype now needs an on-demand left-palm toolbox, contextual object controls, and reusable presets. Direct object-channel editing and the continuously visible head-following debug pane from decision 0003 no longer describe the desired interaction.

## Decision

Reveal a two-column toolbox using left-palm orientation plus device viewing direction. Exact eye gaze is not exposed by visionOS. Debounce the tracked pose and freeze the pane position while open; preserve it briefly during preset dragging. Provide an explicit Simulator preview and a manual fallback when hand tracking is unavailable.

The library column scrolls actions, presets, and objects. The recent column maintains a unique most-recent-first list capped at ten, with an instructional empty state. Object selection expands its label above the cube with Info and Delete. Info is read-only and grows the same label.

A separate preset window owns channel editing and library management. Save propagates validated channel values/count to every assigned fixture; Save as New creates an independent identity. Drag/drop and Apply Saved assign the saved preset. Instance patches and positions remain with fixtures. A failed footprint validation rejects the whole transaction. Clearing a draft takes effect only on Save. Deleting a preset or clearing an assignment zeros affected values and removes the link.

Normal presets persist locally; demo presets, scene fixtures, recents, and draft edits are session-only. The mock API still sends the full resolved fixture snapshot and now includes optional preset identity.

## Consequences

The core library and session tests can validate preset semantics and temporal palm gating on macOS. Device builds validate ARKit availability, but palm orientation, drag/drop between SwiftUI attachments, comfort, and gaze-targeted interaction require interactive headset acceptance. This is still an R&D subset of the product domain, not the full show/venue/profile model.
