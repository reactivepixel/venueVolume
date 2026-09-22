---
type: decision
status: accepted
date: 2026-09-19
owners:
  - company
---

# 0001 - Repository and Documentation Structure

## Context

Venue Volume is beginning R&D for a DMX lighting controller. The workspace needs to hold future applications, services, shared code, hardware artifacts, and company/product/engineering knowledge without assuming a final architecture.

Documentation needs to be easy to navigate and edit locally while remaining portable and reviewable in version control.

## Decision

Use this repository as the top-level workspace for all project materials. Keep runtime code in `apps/`, `services/`, and `packages/`; supporting materials in purpose-specific root directories; and canonical documentation in `docs/`.

Treat `docs/` as an Obsidian vault built from standard Markdown, YAML frontmatter, relative assets, and wikilinks. Commit shared Obsidian settings but ignore per-user workspace state.

## Consequences

- Product, technical, and company context can evolve beside implementation.
- The vault is usable in Obsidian and still readable in a text editor or code review.
- Root boundaries are available before the implementation architecture is selected.
- Contributors must keep links and canonical notes current as experiments resolve uncertainty.

## Alternatives considered

- **Documentation mixed into code folders:** useful for component-specific material but weak as the company-wide knowledge entry point.
- **Hosted proprietary documentation only:** easier collaboration in some cases, but adds an external dependency and weakens proximity to code and decisions.
- **Single flat notes directory:** initially simple, but harder to scan as product and engineering research grows.

