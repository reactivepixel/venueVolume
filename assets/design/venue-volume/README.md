# Venue Volume — wireframes and high-fidelity mockups

Open `index.html` in a browser for the complete screen gallery. Switch between wireframes and high fidelity, filter by section, search by feature, and click a screenshot to inspect it at full size.

- `wireframes/`: 35 structural screen designs.
- `high-fidelity/`: 35 refined desktop screens at 1440px width.
- `mobile/`: 8 representative 390px layouts.
- `dialogs/`: 9 shared create/review flows.
- `states/`: empty, loading, error, and permission examples.
- `marketing/`: historical marketing explorations plus the canonical `selected-void.png` capture.
- `wireframes-contact-sheet.png` and `high-fidelity-contact-sheet.png`: full-screen-set overviews.
- `manifest.json`: screen IDs, purposes, feature mapping, viewport sizes, and export counts.

Screens are generated from the React app in `apps/design-studio`. Use the interactive app to review scope changes, preset inheritance, patch validation, script editing, and simulated playback. All data and output are illustrative.

Feature requirements and design notes live in the Obsidian vault under `docs/02 Product/Features` and `docs/02 Product/Design`.

Revision 02 adds the desk-style live console and the three color-coded workflows. Extra captures: `high-fidelity/live-popout.png`, `high-fidelity/live-cue-inspector.png`, `dialogs/live-midi-mapping.png`, and `mobile/live-touch-tablet.png`. Run `npm run test:live` to regenerate these interaction-state captures; `npm run export:screens` regenerates the baseline screen set and gallery.

The marketing captures are review artifacts generated from `apps/marketing`, not part of the 35-screen product gallery. The application now ships only the selected Void direction.
