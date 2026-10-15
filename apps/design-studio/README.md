# Venue Volume SaaS workspace

The React workspace connects scanned venues, physical fixture inventory, Load Outs and Tours with palette/phaser programming and simulated cue playback. Each Load Out owns its browser-local programming data. There is no physical lighting output or automatic native synchronization.

## Run

Use Node.js 22.19+ and npm. Check the intended port first, then:

```sh
npm ci
npm run dev -- --port 5174 --strictPort
npm run build
```

Start the [venue intake service](../../services/venue-ingest/README.md) alongside Vite for movie uploads. `VV_INTAKE_URL` selects its local address. Movies follow the [roomScan pipeline](../roomScan/README.md): references, reviewed geometry, Blender and USDZ.

## Programming

Open **Programming**, select a Load Out and open **Palettes & phasers**. The selected fixture list grows as fixtures or roles are added. Fifteen standard palettes cover All, Intensity, Color, Position, Beam and Phaser pools beside the editor. Static/Dynamic controls share the same draft, flat fixture diagram, playback clock and attribute ownership rules.

Dynamic palettes expose tap tempo, numbered steps, step count, bar-length shortcuts, Wave/Breath/Pulse patterns, a cycle graph, linked static presets, transition and phase distribution. Selecting a step opens its configuration. Recent step configurations can be recalled during the editing session.

The context bar tracks cues **01–255** and collapses to an ellipsis when nothing is selected. Valid fixture edits save to the current cue after a short idle period; **Store to…** targets another numbered cue. Unchanged attributes track from earlier cues. Cue drafts are snapshots, independent of reusable pool entries. **Store in preset pool** creates or updates library palettes. Macros flush pending edits, preflight their full palette sequence, and apply to one selection and cue while preserving other attributes.

The 2D preview samples the selected fixtures' cue layers plus the active draft. Pause freezes the diagram and pool swatches. Rehearsal/live remain simulated and use the same palette sampler.

## Room and fixture review

The 3D review loads native venue saves containing USDZ or scanned meshes and the catalog fixture models. It supports GLB export, isometric images, saved review snapshots and transform inspection. RoomScan exports should keep `environment.json` beside `environment.usdz`.

**Place in Vision Pro** creates a `venuevolume://place` link with matching Load Out and fixture UUIDs. The native Load Out must already exist; the link is navigation, not transfer.

## Verification

Automated test suites, browser harnesses and their dependencies were removed at the owner's request. Use production builds, browser interaction review and native build/device checks. Historical screenshots in `assets/design/venue-volume` document earlier designs and are not the current UI contract.

Current browser captures: [desktop programmer](../../docs/03%20Design/saas-roomscan-programmer/desktop.png) and [mobile programmer](../../docs/03%20Design/saas-roomscan-programmer/mobile.png). Direct browser review covered selection, Static/Dynamic switching, phaser steps, preview pause, cue tracking, macro preservation/undo, and responsive overflow.
