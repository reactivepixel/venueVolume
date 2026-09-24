# Venue Volume

Venue Volume is an early-stage company researching and developing a software-based DMX lighting controller.

This repository is the top-level workspace for the company's software services, shared packages, documentation, research, and supporting assets.

## Repository map

```text
.
├── apps/          # User-facing applications
├── services/      # Backend and device-facing services
├── packages/      # Shared libraries and reusable modules
├── docs/          # Obsidian vault and canonical project documentation
├── assets/        # Shared non-code source assets
├── hardware/      # Hardware notes, fixtures, and interface research
├── infrastructure/# Deployment and operations configuration
├── scripts/       # Repository-level development scripts
└── tests/         # Cross-service and system-level tests
```

## Documentation

Open [`docs/`](docs/) as an Obsidian vault, then begin at [`Home`](docs/Home.md). The documentation remains ordinary Markdown and can be read without Obsidian.

Agents working concurrently should follow [AGENTS.md](AGENTS.md) for worktree, port, and `dev` integration rules.

## Product design study

The [React design studio](apps/design-studio/README.md) contains 35 screens with wireframe and high-fidelity modes, simulated interactions, and responsive layouts. Run `npm ci` and `npm run dev` in `apps/design-studio`.

Browse the [static screen gallery](assets/design/venue-volume/index.html) for exported mockups. The [feature catalog](docs/02%20Product/Features/Feature%20Catalog.md) defines requirements across the interface, API, storage, domain model, local output runtime, and operations. The [interaction coverage](docs/02%20Product/Design/Interaction%20Coverage.md) distinguishes functional demo behavior from presentation-only flows.

## Marketing study

The [Astro marketing app](apps/marketing/README.md) is a statically rendered, one-page private-alpha signup using the selected Void visual direction. Its email/phone submission is intentionally mocked in the browser console until the lead-storage integration is selected.

## Current phase

The project is in R&D. Current work should favor measurable experiments, explicit assumptions, and recorded decisions over premature production architecture. See the [R&D backlog](docs/04%20Research/R%26D%20Backlog.md) for the initial research tracks.
