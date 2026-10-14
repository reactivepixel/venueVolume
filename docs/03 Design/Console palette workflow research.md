# Palette and phaser workflow redesign

Research and implementation: 6 October 2026. Applies to the SaaS design studio and visionOS app.

## Sources and decisions

| Primary source / tutorial | Finding | Venue Volume decision |
| --- | --- | --- |
| [MA University: Video Tutorials / MA Tips](https://www.malighting.com/ma-university/video-tutorials/) and [First steps](https://www.malighting.com/ma-university/first-steps/) | Official learning routes cover console setup and programming. | Provide a legible programming sequence, not an imitation of the console command line. The linked video catalogue was inspected; no claim is made to have watched every video or completed the gated course. |
| [grandMA3: First patch](https://help.malighting.com/grandMA3/2.4/HTML/qsg_first_patch.html) | Patch establishes fixtures before programming looks. | Application always names its fixture selection; empty selections cannot apply. Groups provide a quick selection method. |
| [grandMA3: Presets](https://help2.malighting.com/grandMA3/2.4/HTML/presets.html) and [Preset pools](https://help2.malighting.com/grandMA3/2.4/HTML/presets_pools.html) | Presets are reusable references; feature-group pools filter stored attributes. Selective/global/universal describe distinct fixture-resolution behavior. | Separate pool browsing, editing and application. Dimmer, Color and Position pools own only their attributes; native Beam owns beam width. All contains combined looks. Do not expose unsupported preset-mode switches. |
| [grandMA3: Create a sinus dimmer phaser](https://help.malighting.com/grandMA3/2.4/HTML/phaser_create_dimmer.html) | Start with fixture selection and two dimmer presets, then adjust timing and distribute phase. | Numbered steps with static palette sources or custom values; Together, Wave and Reverse wave shortcuts; BPM, cycle beats, width and transition controls. |
| [grandMA3: Phasers](https://help.malighting.com/grandMA3/2.4/HTML/phaser.html) | Static and multistep data share the preset workflow; speed, phase, width and transition describe separate properties. | Static / Phaser is a mode within an attribute pool, not a separate incompatible library. Show a continuous preview and the resulting cycle duration. |
| [grandMA3: Recipe editor](https://help.malighting.com/grandMA3/2.4/HTML/recipe-sheet.html) | Recipes separate selection from value references and distribution. | SaaS application writes selected fixture references into a destination cue, preserving group defaults and independent attribute layers. Step sources remain linked. This is a focused reference workflow, not a complete MA recipe engine. |
| [grandMA3: Circle around a position preset](https://help.malighting.com/grandMA3/2.4/HTML/phaser_create_circle_preset.html) | Relative motion can be combined with absolute position. | Record this as a distinct engine capability. Current circle examples remain absolute; the UI does not imply relative/additive motion is supported. |
| [ETC: Using focus palettes](https://support.etcconnect.com/ETC/Consoles/Congo_Cobalt/Software_and_Programming/Using_Focus_Palettes) | Focus presets reference palettes; palette application affects selected fixtures. | Preserve independent dimmer/color/position layers and make selected-only application explicit. |
| [ETC: Controllable properties of light](https://blog.etcconnect.com/stage-lighting-design-part-3) | Intensity, color, distribution and movement serve visibility, form, composition, mood and information. | Use meaningful attribute labels and a visible lighting preview. Keep setup controls separate from cue application so composing a look does not unintentionally overwrite another part of the design. |

These sources establish the programming pattern; layout and interaction choices are Venue Volume design decisions. Manuals are linked to the inspected 2.4 edition, not presented as an exhaustive description of all current grandMA3 features.

## Interface design

Visual thesis: a quiet, dense programming workspace with neutral surfaces, cyan selection state and color used for actual light values.

Content plan: attribute pools on the left; name, pool and lighting preview at the top; static values or one numbered step in the central editor; store/update beneath, with fixture selection and cue application in a strip above the workspace. Native uses a pool sidebar and a pinned selection/apply strip with gaze-sized controls.

Interaction thesis: pool selection highlights immediately; changing steps reveals only that step's values; continuous multi-fixture preview makes phase distribution visible. Preview playback is pausable on the web. Draft switching preserves unsaved work through explicit save/discard/keep-editing choices.

## Shared workflow

1. Choose a pool and a palette, or create a new palette in a pool. Editing does not apply it.
2. Set only the attributes owned by that pool. Color changes do not bring dimmer or position values with them.
3. For movement or modulation, choose Phaser steps. Each step uses custom values or references one existing static palette that covers the phaser's attributes.
4. Set cycle speed, measure, phase spread and step widths; inspect preview. A full spread divides fixtures across the cycle without duplicating the endpoint.
5. Store a new palette or update the existing one. Duplicating creates an independent palette; linked static step sources remain explicit references.
6. Select fixtures or a group, then apply the saved palette. Native applies to the venue selection in one history action. SaaS stores fixture-level references in the chosen cue, above that cue's role defaults. Applying requires saved values and a nonempty selection.

## Behavioral contract and scope

- Stored palette references are retained across SaaS renames, including layered cue assignments and step sources. Native references use UUIDs.
- Step sources are static only and must cover the destination attributes. Nested dynamic references and cycles are not offered.
- Native portable setups include step dependencies. Deleting a linked source is blocked with an actionable message.
- Channel ownership is explicit. Changing an assigned native palette's pool cannot silently strand existing channel bindings.
- Native phase distribution follows fixture list order. SaaS follows the snapshot fixture order. This release does not implement MAtricks grids, wings/blocks, arbitrary selection ordering, selective/global/universal data resolution, speed masters or relative layers.
- Timing retains the existing Venue Volume contract: beats per complete cycle, widths as normalized ratios, and transition as a hold-then-interpolate fraction. This differs from grandMA3's full step-layer timing model and is labeled accordingly rather than claiming console file compatibility.
- SaaS currently models dimmer, RGB color and position. Native exposes the synthetic VV Preview 16 beam control too. Neither sends network DMX; this is not a grandMA3 show-file importer.

## Acceptance checks

Verify source-palette edits propagate to linked steps; renames preserve references; static color does not change intensity; fixture overrides layer above group defaults; a later static assignment stops an earlier phaser only for its attributes; application touches only selected fixtures. Verify duplicate/store/reload, dirty-navigation protection, an empty-selection disabled Apply, phase preview, native dependency export and Undo.

## Validation

- Design studio: 39 model tests passed and Vite production build passed. Browser checks passed for pool navigation, duplicate/store/reload, static-source links, dirty-draft protection, selected-only application, renamed source persistence, group cue recipes, restoring group values and desktop/narrow layouts.
- visionOS: core tests (9 XCTest plus 109 Swift Testing tests) and the session smoke suite passed, including linked-source sampling, validation, portable dependency closure, selected group application and Undo. The Simulator app builds with the redesigned editor.
- Hardware hand/gaze interaction has not been validated for this redesign. Console networking, relative motion and complete MAtricks behavior remain outside this implementation.
