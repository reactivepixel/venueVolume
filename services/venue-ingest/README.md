# Venue movie intake

The design studio can now save actual venue movies and process them through
`apps/mov2splat/scripts/host.sh`. This is a single-host service with SQLite
metadata, streamed uploads on disk and a serial GPU queue. It uses Python's
standard library; no additional Python packages are needed.

## Run

From the repository root, first check that port 8788 is free:

```sh
ss -ltn '( sport = :8788 )'
python3 services/venue-ingest/server.py --port 8788
```

In a second terminal, check that port 5174 is free, then run the design studio:

```sh
ss -ltn '( sport = :5174 )'
cd apps/design-studio
npm ci
npm run dev -- --port 5174 --strictPort
```

- **In the workspace:** open `http://127.0.0.1:5174/?screen=venues`, choose
  **Add venue → From a movie**, name the venue and choose its configuration.
- **Capture for later:** open `http://127.0.0.1:5174/upload`. Only a movie is
  required. Its filename supplies the initial name; the venue remains marked
  **Needs setup** in the shared **Venue inbox**.
- **Finish later:** open the inbox item, wait for **Splat ready**, then choose
  its name, show and starting configuration. **Import venue into show** updates
  the existing record and retains the source movie and splat.

If 8788 is occupied, choose another available port and set
`VV_INTAKE_URL=http://127.0.0.1:<port>` when starting Vite. Use the same hostname
in the browser throughout development. After `npm run build`, the intake
service also serves the built application and `/upload` directly at its own
URL; Vite is then unnecessary. `vite preview` does not provide the API proxy.

Processing requires the existing [Movie2Splat host setup](../../apps/mov2splat/README.md):
Docker, an NVIDIA GPU, NVIDIA Container Toolkit and access to the Docker daemon.
No reconstruction happens in the browser. The launcher builds its image when
needed; a first run may take longer. The service does not install host packages.

## Storage and lifecycle

The default data directory is `.venue-ingest/` at the repository root, ignored
by Git. Use `--data-dir /absolute/persistent/path` to keep recordings outside
an ephemeral checkout or worktree. Back up that whole directory together,
including SQLite and each venue's files. Deleting browser storage does not
delete uploaded venues. Deleting the service data directory does.

Each venue has a UUID, original filename, byte size, SHA-256, creation/update
times, processing attempts, pipeline stage, setup status, show/configuration
labels and optional city. Files use service-owned names under that UUID:

```text
.venue-ingest/
  venues.sqlite3
  <venue-uuid>/
    source.mov                 # or .mp4 / .m4v, original bytes
    source.ply                 # validated Gaussian result
    source.gsplat/             # pipeline status, frames, resume checkpoints
    processor.log
```

Uploads stream to a temporary file and atomically become the source only after
the declared byte count and movie signature pass validation. Default maximum
size is 10 GiB, configurable with `--max-upload-bytes`. Container-side ffprobe
and reconstruction validate decodability and scene suitability. A supported
extension/signature alone does not guarantee successful reconstruction.

Processing states are `awaiting_upload → uploading → queued → processing → ready`.
Pipeline failures become `failed`; retry returns the same record to `queued`
and invokes the launcher with `--resume`. A successful exit without a valid
Gaussian PLY is also a failure. Setup is independent: standalone records remain
`needs_setup` even after processing, while records assigned to a show are
`configured`. These labels do not assert lighting, scale or show readiness.

One worker processes queued jobs in arrival order. Run one service for a shared
GPU/data directory and avoid concurrent manual Movie2Splat jobs. A file lock
prevents duplicate services using that directory, and an inherited processor
lock prevents a replacement worker overlapping a surviving launcher after a
crash. Graceful shutdown waits for the active job. Restart recovers finished
exports, marks interrupted processing retryable, and resumes queued jobs.
Interrupted uploads can be repeated with the same venue ID and original file;
upload transfer itself restarts from byte zero. Keep the upload page open until
the movie is saved; processing continues independently afterward.

## HTTP contract

All paths use `/api/venues`. JSON requests require `Content-Type: application/json`.

| Method/path | Behavior |
| --- | --- |
| `GET /api/venues` | List persisted records and `maxUploadBytes` |
| `POST /api/venues` | Reserve a venue using UUID `idempotencyKey`, `filename`, integer `size`, optional `name`/`city`, and either both `show`/`template` or neither |
| `GET /api/venues/:id` | Read the record and current pipeline stage/frame counts |
| `PUT /api/venues/:id/movie` | Stream original bytes with matching `Content-Length`; queue only after successful storage |
| `POST /api/venues/:id/retry` | Retry a failed processing job with JSON `{}` |
| `POST /api/venues/:id/setup` | For a ready result, save `name`, `city`, `show`, `template` and mark configured |
| `GET /api/venues/:id/splat` | Download the ready Gaussian PLY |
| `GET /api/venues/:id/log` | Download the processing log |

Reusing the same idempotency key and original reservation payload returns the
same record. Conflicting reuse and invalid lifecycle transitions return 409.
Upload progress reports bytes transferred; pipeline stages are not fabricated
percentage estimates. The UI polls status every three seconds.

## Current boundary

The service binds to `127.0.0.1`, accepts local hostnames, rejects cross-origin
browser requests and exposes no CORS access. It is intended for the repository's
local SaaS prototype. Production identity, tenant isolation, storage quotas,
remote object storage and a managed GPU worker are not implemented. Show and
configuration selections are the existing prototype's labels, not revisioned
production IDs. Do not expose this service as a public upload endpoint without
those controls. The existing manual **From a template** flow remains a local
demo, as do CAD, fixture mapping and physical output.

A splat is a captured visual environment. This integration does not convert it
to editable CAD, Blender geometry or USDZ, and does not replace the separate
room2blender workflow.

## Checks

From the repository root:

```sh
python3 -m unittest discover -s tests/venue_ingest -v
python3 -m unittest discover -s tests/mov2splat -v
cd apps/design-studio
npm test
npm run test:venues
```

The browser test builds the app and starts its own real intake HTTP service,
database and filesystem on an OS-assigned unused port. Only the costly GPU
launcher is replaced by a deterministic fixture. It verifies both entry points,
the deferred setup/import path, fresh browser sessions, download, failure/retry,
connection errors, validation and mobile layouts. Review images go to ignored
`tmp/venue-upload-review/`. These tests do not claim a real GPU reconstruction.
Install Chromium using `npx playwright install chromium` if needed; for a
worktree-local installation set `PLAYWRIGHT_BROWSERS_PATH=0` both when installing
and when running browser checks.
Alternatively, set `VV_CHROMIUM_EXECUTABLE=/absolute/path/to/chromium` for the
venue browser test to use an existing Chromium installation.
