# Venue Volume design studio

An interactive React design study with 35 product screens in both wireframe and high fidelity. It is a local mockup: no authentication, billing, cloud storage, CAD conversion, or DMX/Art-Net output is implemented.

## Run

Requires Node.js 22 or newer and npm.

```sh
npm ci
npm run dev
```

Open the URL printed by Vite. Start at the show overview, use the **35 screens** browser, and switch between **01 Wireframes** and **02 High fidelity**. The state selector shows shared empty/loading/error/permission patterns. Links are shareable locally, for example `/?screen=live&mode=hifi&state=ready`.

```sh
npm test
npm run build
npx playwright install chromium
npm run test:browser
npm run test:live
npm run test:slots
npm run export:screens
```

Browser checks and export expect the dev server on `http://127.0.0.1:5173`; set `VV_BASE_URL` to use another address. Screenshots and the static gallery are generated under `assets/design/venue-volume` at the repository root. Font loading uses Google Fonts with local sans-serif fallbacks; production bundling is otherwise local.

The demo persists selected sample data under `vv-design-v1` in localStorage. Remove that single key in browser developer tools to restore the sample dataset. Exports use isolated browser contexts so local edits do not change baseline screenshots.

See the Obsidian vault's `02 Product/Design` and `02 Product/Features` directories for screen coverage, prototype limits, and requirements beyond the UI.

Script entries appear in vertical numbered slots. In the script editor, drag a grip with mouse or touch to another slot, use arrow keys on the focused grip, or use the move buttons. Escape or dropping outside cancels. Slot numbers change; entry IDs, cue IDs, timing, notes, and MIDI mappings do not. The live console's **Edit running order** opens the editor; live slots are not draggable, and armed draft reorders use **Review & apply**.

The revised live console includes stage/group selection, a manual programmer, masters, a merged bottom script timeline, song restart, MIDI mapping/test input, and a synchronized pop-out. **Back / Next** immediately step through script occurrences. **Hold** retains the cue and becomes **Play**, which resumes cue intake without advancing or replaying buffered triggers. Secondary **House** restarts from the configured house cue (demo: House open); it is not independent house-light control. **Blackout** retains its separate latch. Use **Pop out console**, then edit the venue in the original window. Run state is stored separately under `vv-live-v2:` keys. **Review & apply** accepts edits for future calls without replacing the active look. Rehearsal has its own session.

Optional physical input uses Web MIDI after **Connect MIDI device** permission. Test triggers need no hardware. **Keep awake** requests a visible-window wake lock when supported; browsers cannot guarantee OS always-on-top or background execution. Lighting output remains simulated and physical MIDI is unvalidated.
