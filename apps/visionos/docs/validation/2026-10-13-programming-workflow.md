# Palette, phaser and macro workflow validation

Implemented in `agent/console-palette-workflow`, with first-party MA tutorial research in `docs/04 Research/grandMA3 Programming Workflow.md`.

- Swift core: 12 XCTest cases and 109 Swift Testing tests passed. Includes transition-before-hold, per-step overrides, tap-tempo reset, independent step count/cycle duration, macro scopes, missing references, disabled rows, serialization and repeatability.
- Session suite passed, including ordinary and touring macro execution, a failed later action causing no partial write, non-target fixture preservation, one Undo/Redo, macro persistence, empty-selection guards, compact context state and wrist routing.
- Native Simulator build and signed visionOS device build succeeded.
- Installed and launched on the paired physical Vision Pro after unlock. Programmatic runtime checks passed for selection/context collapse, target cancel/save/Undo, eight-step source-linked programming at 120 BPM over eight beats, macro execution and Undo. The initial locked/disconnected launch failed; the final unlocked run succeeded. See `evidence/2026-10-13-programming/device-smoke.txt`.
- The same runtime checks passed in Simulator. Native rendering was inspected; a cramped header action and overflowing compact ellipsis button were corrected. Full hand/gaze interaction and all accessibility sizes still need human testing.
- SaaS: 41 model tests passed; production Vite build succeeded. The browser workflow passed timing independence, linked source editing, macro run/Undo, persistence after reload, dirty and empty-selection guards, and a 700-pixel layout without horizontal overflow. `tests/programming-browser.mjs` uses `VV_BASE_URL` and optional `VV_CHROMIUM_EXECUTABLE`.

The device run uses isolated demo data, not saved user venues. Macro actions recall saved palette references; this is an app workflow, not an MA console macro interpreter. The SaaS remains the existing browser-persisted programming preview. The task branch is retained for integration; this change does not promote `master` or create a release tag.
