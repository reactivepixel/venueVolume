---
type: verification
status: passed-prototype-checks
updated: 2026-09-21
---

# Verification Record

The checks below apply to the React design prototype and exported artifacts, not production DMX timing, safety, authentication, billing, or CAD conversion.

## Results

| Check | Result |
| --- | --- |
| Production client build | Passed with Vite 6.4.1 and Node 22.14.0 |
| Domain model tests | 15 cases across 2 test files passed (original model + live runtime) |
| Browser screen/layout/interaction checks | 117 passed; no browser console or page errors |
| Desktop route coverage | All 35 routes in both wireframe and high fidelity |
| Narrow layout coverage | All 35 routes at 390px; no document-level horizontal overflow |
| Export coverage | 70 desktop screens, 8 mobile examples, 9 dialogs, 4 shared states, 2 contact sheets |
| Documentation links | 159 non-example wikilinks resolved across 40 notes before this record was added |

## Revision 02 live-console checks

The full 117-check browser suite passed again after the live-console rewrite. A separate live suite verified fixture/group/venue selection, manual intensity, cue inspection without activation, synthetic MIDI calls, song restart/re-triggering, actual cue-hit markers, hold/blackout gates, synchronized grand master, no-reload draft updates, continued pop-out operation after closing the editor, saved venue MIDI mapping, and separate venue run isolation. Narrow pop-out checks cover 1024px and 390px. A wide-window assertion verifies the console stays inside its viewport with docked transport.

The live domain cases cover zero/manual precedence, per-fixture relative nudge, master scaling, release, MIDI filtering, restart passes/history, active-look preservation on draft apply, structural-update rejection while armed, and disconnected/unknown output. Browser regression assertions wait for serialized shared-state commands rather than assuming immediate local mutation.

The extended vault has 45 Markdown notes with 201 resolved non-example wikilinks. Export regeneration covers all 35 wireframes/high-fidelity routes, plus extra pop-out, cue-inspector, MIDI-mapping and tablet views. Physical MIDI devices, DMX/Art-Net transport, actual fades/timecode, and production bridge authority remain unvalidated.

Browser interaction checks exercise the screen picker, error retry, venue override/reset/persistence, invalid patch blocking preflight, script reorder and repeated cue references, simulated arm/GO/hold/blackout, simulated disconnect, and local show creation. Domain tests also exercise zero/false overrides, per-universe overlap bounds, end-of-script behavior, and stable script entry identity.

## Revision 03 section-contrast checks

The production client build and dedicated live-browser suite passed after the section-color update. Added assertions verify seven distinct computed section backgrounds, pointer selection highlighting the stage, intensity editing highlighting the inspector, keyboard focus highlighting group masters, and exactly one active section at a time. Existing checks still cover detached-window layout, narrow layouts, cue/MIDI operation, restart, and no-reload synchronization. The detached high-fidelity console was visually inspected with the amber inspector active. The screen gallery and supplementary live captures were regenerated. This is not a full accessibility contrast audit or real-world FOH validation.

## Revision 04 unified playback checks

Build, 13 domain cases, the dedicated live browser suite, and all 117 screen/layout/interaction checks passed. The live suite now verifies all six demo cue cards appear once in the bottom playback box, Back immediately recalls the previous cue without a dialog, Hold disables Back/Next while retaining the cue, Play resumes without advancing, and House returns to its configured script entry. Pure model checks verify held MIDI is discarded, subsequent fresh MIDI resumes, boundaries do not wrap, Back resets forward replay eligibility, House mapping absence is safe, and repeated song labels preserve script order. Six functional section colors remain after merging playback and timeline. The disconnect browser assertion now waits for asynchronous shared-state propagation. Detached-console screenshots were visually inspected and the gallery refreshed. No physical output or independent house-light circuit control is claimed.

## Revision 05 vertical cue slots

Build, 15 domain cases, the dedicated live suite, the new slot browser suite, and all 117 screen/layout/interaction checks passed. Slot checks cover vertical numbering, insertion rather than swapping, stable per-entry defaults, mouse drag, real browser touch events, arrow-key movement, Escape cancellation, dropping outside, saved order after reload, repeated cue identity, and draft reordering with live review while retaining the active cue. Live cue slots have no drag controls. Browser contexts use synthetic data; production revision conflicts and venue-specific sequence persistence remain to implement.

## Visual review

Inspected rendered desktop overview, live console, template-editor wireframe, and mobile live console. Corrected SVG icon sizing in stage previews and neutralized remaining wireframe decoration. Rebuilt, reran browser checks, and regenerated all exports after those corrections.

## Reproduction

See `apps/design-studio/README.md`. Run the local development server, then `npm test`, `npm run build`, `npm run test:browser`, and `npm run export:screens`. The browser suite uses fresh contexts and synthetic data; it does not require user accounts or lighting hardware.

The validation environment did not initially provide Node or Chromium libraries. Node 22.14.0 was downloaded to a temporary directory with its archive hash compared to the official checksum list. Playwright used its Ubuntu 24.04 browser build on this Ubuntu 26.04 environment, with missing runtime libraries extracted into a temporary directory. A normal development installation needs Node and the standard Playwright browser dependencies; these temporary paths are not application dependencies.

## Remaining validation

Human workflow review, full accessibility/contrast auditing, real CAD samples, complete editor persistence, API contracts, concurrency, authentication, cloud/local recovery, hardware compatibility, output timing, and physical fixture behavior remain implementation/R&D work. See [[Interaction Coverage]] and [[../Features/Feature Catalog]].
