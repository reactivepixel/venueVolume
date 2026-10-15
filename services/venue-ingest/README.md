# Venue intake and roomScan

A local Python service stores original MOV/MP4/M4V recordings and processes them with the [roomScan pipeline](../../apps/roomScan/README.md). The pipeline extracts references, waits for an explicitly reviewed room specification, then builds an editable Blender scene and a USDZ environment. It does not infer a finished room automatically.

## Run

Use Python 3.12+, uv, FFmpeg and Blender 4.5+. Install the pipeline dependencies with `uv sync --locked --project apps/roomScan`. Check port 8788 before starting:

```sh
uv run --locked --project apps/roomScan python services/venue-ingest/server.py --port 8788
```

Run from the repository root. Set `BLENDER_BIN` to the Blender executable when it is not on PATH; on macOS this is typically `/Applications/Blender.app/Contents/MacOS/Blender`. The service binds to localhost. The design studio proxies `/api/venues` to it; set `VV_INTAKE_URL` for another local port. Build the design studio first to serve its production output directly from this service. No Docker or GPU service is required.

## Workflow

1. Upload a movie in **Scanned venues → Add venue** or `/upload`.
2. When the status is **Room review required**, download the reference contact sheet and draft room specification.
3. Review dimensions, room openings, placement surfaces, assumptions and source evidence. Complete the JSON and its review fields.
4. Upload the reviewed specification from the venue detail page. The worker validates it against the source movie before invoking Blender.
5. Download the Blender scene, USDZ and environment manifest. Keep the manifest beside the USDZ when importing a bundle into the native app. For bundled Xcode rooms, follow the roomScan handoff guide.
6. Name the completed venue, then create a Load Out and select its fixture inventory.

The worker runs one job at a time and holds a process lock across child execution. Uploads use stable UUIDs, atomic file replacement and SHA-256. Interrupted uploads can resume from a fresh upload; failed processing can be retried against the same source. A reviewed specification is bound to the movie checksum. Pipeline errors remain visible with a downloadable log.

## Storage

The default `.venue-ingest/` directory contains `venues.sqlite3` and a folder per venue UUID. Each folder holds the original movie, `processor.log`, an optional `reviewed-room.json`, and `roomScan/` captures and immutable build runs. Source recordings and operator reviews are retained. This directory is ignored by Git.

## Routes

| Route | Purpose |
| --- | --- |
| `GET /api/venues` | List stored movies and current processing state |
| `POST /api/venues` | Reserve an upload using a UUID idempotency key |
| `PUT /api/venues/:id/movie` | Upload the original movie |
| `POST /api/venues/:id/review` | Submit a reviewed room specification |
| `POST /api/venues/:id/retry` | Retry a failed job |
| `POST /api/venues/:id/setup` | Name and configure a completed venue |
| `GET /api/venues/:id/references` | Download the contact sheet |
| `GET /api/venues/:id/draft` | Download the draft specification |
| `GET /api/venues/:id/model` | Download USDZ |
| `GET /api/venues/:id/manifest` | Download environment JSON |
| `GET /api/venues/:id/blend` | Download the editable Blender scene |
| `GET /api/venues/:id/log` | Download the processing log |

This service is for trusted local use. It provides no accounts, remote authorization or multi-host job coordination. Browser Load Outs and native saves remain separate; the Vision Pro placement link navigates to matching existing native IDs and does not transfer their data.

## Verification

A manual end-to-end run on 2026-10-15 uploaded a synthetic movie, paused for review, accepted the reviewed specification through the browser, and completed Blender 4.5.14 rendering and USDZ export. The export passed the pipeline's geometry, manifest, OpenUSD and Blender reimport checks. All three output downloads retained their expected filenames. This checks the handoff, not the accuracy of a measured venue or rendering on a headset.
