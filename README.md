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

## Product design study

The [React design studio](apps/design-studio/README.md) contains 35 screens with wireframe and high-fidelity modes, simulated interactions, and responsive layouts. Run `npm ci` and `npm run dev` in `apps/design-studio`.

Browse the [static screen gallery](assets/design/venue-volume/index.html) for exported mockups. The [feature catalog](docs/02%20Product/Features/Feature%20Catalog.md) defines requirements across the interface, API, storage, domain model, local output runtime, and operations. The [interaction coverage](docs/02%20Product/Design/Interaction%20Coverage.md) distinguishes functional demo behavior from presentation-only flows.

## Marketing study

The [Astro marketing app](apps/marketing/README.md) is a statically rendered, one-page private-alpha signup using the selected Void visual direction. Its email/phone submission is intentionally mocked in the browser console until the lead-storage integration is selected.

## mov2splat

[mov2splat](apps/mov2splat/README.md) converts one iPhone Camera `.mov` into a standard 3D Gaussian Splatting `.ply` on the same machine. It runs headlessly in a Docker image using the host NVIDIA GPU. The first run builds the image; later processing runs without container networking.

On Omarchy, keep the existing NVIDIA driver and set up Docker GPU access:

```bash
sudo pacman -S --needed docker nvidia-container-toolkit
sudo systemctl enable --now docker
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu24.04 nvidia-smi
```

From the workspace root, process or resume one clip:

```bash
./apps/mov2splat/scripts/host.sh /absolute/path/to/clip.mov
./apps/mov2splat/scripts/host.sh --resume /absolute/path/to/clip.mov
```

The result is `/absolute/path/to/clip.ply`. Frames, COLMAP data, trainer output, `pipeline.log`, and `status.json` are saved in `/absolute/path/to/clip.gsplat/`. Use `--resume` after an interrupted run to reuse valid SfM data, or `--force` to replace an existing `.ply`. Run one GPU job at a time. See the [operational runbook](docs/05%20Operations/mov2splat.md) for setup, capture guidance, commands, and failures.

## Gaussian splat viewers

Three demo applications load Gaussian `.ply` environments and start the viewer
inside the scene: [visionSplat](apps/visionSplat/README.md) for Apple Vision Pro,
[unitySplat](apps/unitySplat/README.md) for Unity, and
[unrealSplat](apps/unrealSplat/README.md) for Unreal Engine 5.
Each includes a synthetic room and supports loading a local file. Start with the
[viewer setup guide](docs/05%20Operations/splat-viewers.md).

## Current phase

The project is in R&D. Current work should favor measurable experiments, explicit assumptions, and recorded decisions over premature production architecture. See the [R&D backlog](docs/04%20Research/R%26D%20Backlog.md) for the initial research tracks.
