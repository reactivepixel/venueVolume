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

## Fixture library

The [fixture library](docs/08%20Fixture%20Library/Fixture%20Library.md) holds manufacturer
research, source-backed dimensions and DMX features, and reusable Blender/USDZ models.
Use the [Create Venue Fixture skill](docs/08%20Fixture%20Library/skill/create-venue-fixture/SKILL.md)
with a manufacturer and model number to add or update an entry. The skill and its supporting
validation tools are preserved in the library documentation.

## Product design study

The [React design studio](apps/design-studio/README.md) contains 35 screens with wireframe and high-fidelity modes, simulated interactions, and responsive layouts. Run `npm ci` and `npm run dev` in `apps/design-studio`.

Browse the [static screen gallery](assets/design/venue-volume/index.html) for exported mockups. The [feature catalog](docs/02%20Product/Features/Feature%20Catalog.md) defines requirements across the interface, API, storage, domain model, local output runtime, and operations. The [interaction coverage](docs/02%20Product/Design/Interaction%20Coverage.md) distinguishes functional demo behavior from presentation-only flows.

## Marketing study

The [Astro marketing app](apps/marketing/README.md) is a statically rendered, one-page private-alpha signup using the selected Void visual direction. Its email/phone submission is intentionally mocked in the browser console until the lead-storage integration is selected.

## Venue environment pipeline

[room2blender](apps/room2blender/README.md) is the current venue workflow: movie references
→ reviewed room specification → editable Blender scene, four isometric cutaways, and a
USDZ/environment manifest for [the Swift visionOS app](apps/visionos/README.md).
Dimensions remain explicit estimates until measured. It uses local FFmpeg, Python and
Blender; Docker, COLMAP and Gaussian training are not required.

```bash
./apps/room2blender/room2blender run /absolute/path/to/room.mov --out /absolute/path/to/room-review
```

A new capture stops for geometry/specification review before building. See the app guide
for the review step, dependencies, and the existing classroom example.

## Optional mov2splat experiment

[mov2splat](apps/mov2splat/README.md) remains available for video → Gaussian `.ply`
experiments. It is independent of the current Blender/USDZ venue workflow. Its single
supported launcher is `apps/mov2splat/scripts/host.sh`; it builds the NVIDIA Docker image
on demand. The unused Compose launcher has been removed.

See the [operational runbook](docs/05%20Operations/mov2splat.md) for its 800-frame default,
resume behavior, setup and failures, and the [cleanup review](docs/05%20Operations/mov2splat-review.md)
for retained dependencies and removed resources.

## Gaussian splat viewers

Three demo applications load Gaussian `.ply` environments and start the viewer
inside the scene: [visionSplat](apps/visionSplat/README.md) for Apple Vision Pro,
[unitySplat](apps/unitySplat/README.md) for Unity, and
[unrealSplat](apps/unrealSplat/README.md) for Unreal Engine 5.
Each includes a synthetic room and supports loading a local file. Start with the
[viewer setup guide](docs/05%20Operations/splat-viewers.md).

## Current phase

The project is in R&D. Current work should favor measurable experiments, explicit assumptions, and recorded decisions over premature production architecture. See the [R&D backlog](docs/04%20Research/R%26D%20Backlog.md) for the initial research tracks.
