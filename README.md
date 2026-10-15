# Venue Volume

Venue Volume is an early-stage company researching and developing a software-based DMX lighting controller.

This repository is the top-level workspace for the company's software services, shared packages, documentation, research, and supporting assets.

The SaaS preparation workflow now uses **scanned venues → Load Outs**, with **Tours** supplying shared base inventory and a dedicated Load Out per stop. See the [whole-product UX review](docs/02%20Product/Design/SaaS%20UX%20Review%20-%20Scanned%20Venues%20and%20Load%20Outs.md) and [design studio guide](apps/design-studio/README.md) for current behavior and prototype limits.

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

Browse the [show-equipment hierarchy and renders](assets/fixtures/research/show-equipment.html)
for lighting, atmosphere, effects, video, control, power, rigging, scenery and accessories.
The explorer distinguishes modeled representatives from research-only gaps.

## Product design study

The [React design studio](apps/design-studio/README.md) provides venue preparation, numbered cues, palettes, phasers and simulated rehearsal. Run `npm ci` and `npm run dev` in `apps/design-studio`.

Venue movies can be uploaded in **Venues → Add venue** or through the standalone
`/upload` page. The [venue intake service](services/venue-ingest/README.md) stores
the original movie, queues the roomScan pipeline and keeps unassigned venues in
an inbox for setup later. Start that service alongside the design studio to use
the upload flows.

Browse the [static screen gallery](assets/design/venue-volume/index.html) for exported mockups. The [feature catalog](docs/02%20Product/Features/Feature%20Catalog.md) defines requirements across the interface, API, storage, domain model, local output runtime, and operations. The [interaction coverage](docs/02%20Product/Design/Interaction%20Coverage.md) distinguishes functional demo behavior from presentation-only flows.

## Marketing study

The [Astro marketing app](apps/marketing/README.md) is a statically rendered, one-page private-alpha signup using the selected Void visual direction. Its email/phone submission is intentionally mocked in the browser console until the lead-storage integration is selected.

## Venue environment pipeline

[roomScan](apps/roomScan/README.md) is the current venue workflow: movie references
→ reviewed room specification → editable Blender scene, four isometric cutaways, and a
USDZ/environment manifest for [the Swift visionOS app](apps/visionos/README.md).
Dimensions remain explicit estimates until measured. It uses local FFmpeg, Python and
Blender; Docker, COLMAP and Gaussian training are not required.

```bash
./apps/roomScan/roomScan run /absolute/path/to/room.mov --out /absolute/path/to/room-review
```

A new capture stops for geometry/specification review before building. See the app guide
for the review step, dependencies, and the existing classroom example. The separate
[mappedRoom](apps/roomScan/mappedRoom/README.md) variant adds compact photo-derived
textures and a controlled lighting comparison against the original room.

## Current phase

The project is in R&D. Current work should favor measurable experiments, explicit assumptions, and recorded decisions over premature production architecture. See the [R&D backlog](docs/04%20Research/R%26D%20Backlog.md) for the initial research tracks.
