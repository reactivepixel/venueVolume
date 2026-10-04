# Venue Volume SaaS design studio

The Load Out inventory now offers **Place in Vision Pro**. It opens a handoff dialog with a real `venuevolume://place` link and copy action. This is navigation to an existing native save with matching IDs, not data transfer; newly created browser-local Load Outs cannot yet load automatically on the headset.


The active product prototype uses a shared scanned-venue library, physical fixture inventory, multiple **Load Outs** per venue and **Tours** with base inventory and a dedicated Load Out per stop. Blank room and template-created venue workflows have been removed. See the [whole-product UX review](../../docs/02%20Product/Design/SaaS%20UX%20Review%20-%20Scanned%20Venues%20and%20Load%20Outs.md).

## Run and verify

Requires Node.js 22+ and npm. Check the intended port before launching.

```sh
npm ci
npm run dev -- --port 5175 --strictPort
npm test
npm run build
VV_BASE_URL=http://127.0.0.1:5175 npm run test:browser
VV_BASE_URL=http://127.0.0.1:5175 npm run test:live
VV_BASE_URL=http://127.0.0.1:5175 npm run test:slots
VV_CHROMIUM_EXECUTABLE=/usr/bin/chromium npm run test:venues
```

Set `VV_CHROMIUM_EXECUTABLE` for your installed Chromium. Workspace, live and slot tests default to `/usr/bin/chromium`; venue tests use Playwright's bundled browser if unset. The main browser test defaults to port 5175; legacy console test defaults remain 5173, so use `VV_BASE_URL` consistently.

The workspace browser test also exports actual UI screenshots to ignored `tmp/saas-ux-review/` at the repository root. `npm run export:screens` runs that same workflow. It uses an isolated browser and synthetic scan API responses, and never starts Movie2Splat. The old `tests/browser.mjs` and `tests/export.mjs` describe the retired 35-screen study and are retained as historical references, not current entry points. Old tracked screenshots under `assets/design/venue-volume` are historical.

## Preparation workflow

1. **Scanned venues** → upload a movie → monitor processing in the inbox → import the ready scan.
2. **Fixture inventory** → add actual physical units with model, footprint, role and ownership.
3. **Load Outs** → choose an imported scan → select inventory → enter placement coordinates → patch → review.
4. Optional: **Tours** → choose shared base units → add venue stops. Every stop creates its own unplaced/unpatched Load Out. Add local inventory at that stop without changing the base. Review subsequent base changes explicitly.
5. **Programming** and **Rehearsal & live** open the existing design previews in a selected Load Out context. They retain sample programming and simulated output.

Placement currently uses numeric X/Y/Z/yaw controls and a clearly labeled schematic with a link to the scan. It does not render the Gaussian splat or calibrate scale. This remains a release blocker for finished spatial preparation UX.

Preparation uses `vv-workspace-v2` in localStorage; exports contain unit IDs, Tours, Load Outs and scan references. Programming previews use `vv-programming-preview:<loadoutId>`; simulated live/rehearsal sessions are also scoped by Load Out ID. Old `vv-design-v1` sample data is not automatically interpreted as scanned rooms or physical units. Cloud preparation persistence, authentication, membership, billing, hardware output and native sync are not implemented.

## Venue movie intake

After checking its port, start `python3 services/venue-ingest/server.py --port 8788` from the repository root. Vite proxies `/api/venues` to it; `VV_INTAKE_URL` selects a different service. Real Movie2Splat processing requires Docker/NVIDIA as documented by that pipeline.

Both workspace upload and `/upload` save a movie as an inbox venue marked **Needs setup**. The standalone page requires only a movie. Processing continues server-side after upload. Import a completed scan by naming it; no show or configuration is required. Multiple Load Outs can then reference that venue UUID. Movie bytes, processing state and splat are persisted by the service, independently of browser preparation state.

`npm run test:venues` builds the app and tests against a temporary actual intake service using a fixture processor. It covers upload validation, persistence, import, failed/interrupted uploads, retry and mobile layout without Docker/GPU use. See the [intake guide](../../services/venue-ingest/README.md).

## Programming previews

Existing script occurrence ordering, cue transport, programmer controls, MIDI test input, hold/blackout, hot-update review and synchronized pop-out remain available for design review. They do not represent production cue/profile binding or hardware output. A later visionOS release will refine the same Load Out; JSON export does not synchronize a headset.

## VisionOS save → web 3D export

In visionOS, use **Export save**. In the SaaS app, open **3D review** (also linked from **Files**) and select that `.venuevolume` file. It becomes an immutable review snapshot with its embedded venue geometry and the actual catalog fixture models. Orbit, pan, zoom, focus a fixture, or choose an isometric corner.

- **Download 3D (.glb)** exports a self-contained glTF 2.0 binary with room geometry, materials, fixture identities, transforms, patch metadata and static articulation. **Open exported GLB** lets another browser review the shared file without fetching the fixture library again.
- **Export all 8 views** produces a ZIP of eight 1600×1200 PNGs plus `views.json`: upper/lower × front/rear × left/right. Each uses an orthographic camera along an equal XYZ direction (35.264° elevation). Front is room-local −Z, right +X, up +Y, in metres. Every view frames the complete room and fixture bounds.
- **See fixtures through venue** makes the room translucent for review and PNG export. It does not change the GLB's full materials or saved geometry. A selected isometric PNG is also available separately. Orbiting or focusing a fixture does not change the standard export cameras.
- Saved snapshots use IndexedDB (`vv-venue-scenes`), separate from editable SaaS preparation. Importing does not overwrite inventory, Tours or Load Outs and does not upload a file to a server. Re-import a newer native save to review changed placement. Browser storage is not a cloud backup; storage failures leave the scene available for immediate download.

Supported room assets are embedded `environment.usdz` and native `environment.mesh.json`. Checks cover save/placement versions, room association, fixture transforms and identity, embedded byte count and SHA-256, mesh indices and catalog-model SHA-256. Missing fixture models or rig parts fail the import explicitly. Failed imports retain the previously open snapshot. The native 350 MB file limit and 64-fixture limit also apply here.

Static joints use the same pivots, axes and channel-to-angle formula as native `FixtureRig`; aim and joint overrides are retained. Continuous motors store speed rather than elapsed phase and are exported at their rest phase. USD PBR material conversion supports the bundled assets; arbitrary USD features may require conversion before import. Live lighting, beams, cues, photometric simulation and visionOS presentation overrides (white room/house-light level) are not baked. Gaussian-splat PLY viewing and automatic SaaS/native Load Out synchronization remain separate work.

The 3D module is lazy-loaded. `fixture-assets.js` serves an allowlist of catalog USDZ models in development and copies them into `dist/fixture-models` for static deployments (~196 MB total). Models download only when a save references their fixture type, once per import. Deploy that directory together with the built app; no Blender, Python converter, GPU pipeline or external CDN is required for export. WebGL2 and a secure context (HTTPS or localhost for checksum validation) are required.

```sh
# With a checked, available Vite port:
VV_BASE_URL=http://127.0.0.1:5177 npm run test:scenes
VV_BASE_URL=http://127.0.0.1:5177 npm run test:scene-catalog
VV_BASE_URL=http://127.0.0.1:5177 npm run test:scene-rooms
```

The scene browser test uses real bundled classroom/fixture assets and a generated native-format save. It checks saved joint poses, GLB transforms/reload/re-import, all eight distinct PNGs, persistence, malformed input, missing assets and mobile layout. The catalog test loads every catalog model, resolves its native rig hierarchy, checks authored metre bounds, exercises a native scanned mesh and checks camera framing. These tests do not start Movie2Splat or modify real venue data. Screenshots, a sample GLB, the source save and the isometric ZIP are written to ignored `tmp/venue-web-export/`.
