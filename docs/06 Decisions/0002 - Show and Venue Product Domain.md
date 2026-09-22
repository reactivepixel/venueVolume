---
type: decision
status: accepted
date: 2026-09-19
owners:
  - product
---

# 0002 - Show and Venue Product Domain

## Context

The founder defined Venue Volume as a React-based SaaS DMX/Art-Net controller with reusable productions that adapt across venues.

## Decision

Use **show** for the project. A show owns configuration templates (drawing plus all production equipment), venues, presets, cues, and scripts. A venue starts from a selected configuration and may adapt locally. Show defaults are inherited unless overridden by the venue. Presets reduce repeated fixture programming; cues define states/moments; scripts define the expected sequence of cues.

## Consequences

The UI, data model, APIs, compiler, runtime, persistence, and tests must share these terms and relationships. Venue adaptations cannot overwrite show defaults. Cue identity must be independent of script order. Inventory must support non-DMX equipment.

Detailed versioning, merge, local bridge, and execution policies remain proposed in [[../03 Engineering/Domain Model]] and [[../03 Engineering/Service and Runtime Boundaries]]. Acceptance of this domain does not imply acceptance or implementation of every architecture proposal.

