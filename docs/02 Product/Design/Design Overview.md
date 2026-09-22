---
type: design
status: prototype
owner: product-design
updated: 2026-09-19
---

# Design Overview

## Deliverables

The local React design study lives in `apps/design-studio`. It contains 35 named screens, each with a wireframe and a high-fidelity rendering. The screen browser links the complete first-pass product surface. See [[Screen Inventory]] for coverage and [[Interaction Coverage]] for functional limits.

Static screen exports live under `assets/design/venue-volume/`. The gallery includes all 70 desktop renders, separate contact sheets for each fidelity, and selected mobile renders. Export files are generated from the actual React screens, not independently drawn pictures.

## Wireframe pass

The first pass establishes navigation, parent/child context, task hierarchy, editable scope, canvas/inspector layout, and operator controls. Wireframes retain meaningful content and exact screen relationships. They replace artwork with labeled placeholders, flatten decorative surfaces into neutral outlines, remove color-dependent styling, and add screen purpose/feature annotations.

Use the `01 Wireframes` switch or a URL such as `?screen=cue-editor&mode=wire`. This is a persistent parallel design view; it is not a claim that a user approved the wireframes before refinement.

## Live console revision 02

[[Live Console Design]] introduces the desk-oriented touch console, live programmer, cue timeline, MIDI, and no-reload pop-out. Pre-programming is violet, venue programming amber, and live teal. The live surface now uses blue-charcoal with teal controls; planning retains its warm base palette.

## High-fidelity refinement

The second pass uses warm ivory surfaces, evergreen navigation, olive actions, restrained amber override indicators, and a dark operating console. Manrope headings and DM Sans body text keep technical screens approachable. CSS/SVG stage graphics are authored for this product; no external fixture or venue photography is required.

Refinement keeps the wireframe's workflow while adding spacing hierarchy, typography, semantic status treatments, provenance badges, production imagery, and readable current/next cue emphasis. Editing and physical operation are visually distinct. Design tool controls appear above the depicted application, not inside a proposed customer workflow.

## Navigation

Workspace → Shows → Show → Configurations / Inventory / Venues / Presets / Cues / Scripts / Files.

Venue detail → Drawing / Patch / Overrides → Preflight → Rehearsal or Live console.

Shared surfaces → Fixture library / Connections / Activity / Team / Settings / Billing.

The top breadcrumb names the current show and screen. An explicit scope switch distinguishes show defaults from venue changes. A venue detail does not imply permission to alter the show default.

## Reusable patterns

| Pattern | Purpose |
| --- | --- |
| Inherited / venue override badge | Show why an effective value exists |
| Scope switch | Prevent edits in the wrong scope |
| Revision pin | Keep template and runtime changes deliberate |
| Stage canvas + equipment + inspector | Relate physical placement to logical fixture identity |
| Cue definition + script entry | Separate reusable state from sequence position |
| Current / next + explicit GO | Make operation predictable |
| Armed / hold / blackout / disconnected | Keep critical runtime states visible in text |
| Empty/loading/error/permission review | Expose non-happy paths during screen review |

## Responsive and accessibility intent

Desktop is the primary programming and operation surface. At narrow widths, columns stack, the sidebar collapses, the screen browser provides navigation, and dense tables scroll inside their own container. This is a responsive mockup, not a validated mobile operating console.

Use native controls, visible keyboard focus, semantic labels, textual status alongside color, and modal focus containment. Do not add a global Space-to-GO shortcut until armed/focus safeguards are designed and tested. Browser tests cover narrow layouts, named controls, state transitions, and browser errors. A full assistive-technology and contrast audit remains a production task.

## Design decisions still open

- Native CAD editing depth versus upload, preview, and fixture annotation.
- Device/OS support and local bridge packaging.
- Preset precedence, non-tracking state policy, fade interruption, and blackout semantics.
- Script follow/timecode/branching scope beyond the expected cue sequence.
- Collaboration roles, offline authorization lifetime, and plan entitlements.
- Venue-specific script replacement versus future fine-grained sequence merging.

## Related

- [[../Features/Feature Catalog]]
- [[Verification Record]]
- [[../../03 Engineering/Domain Model]]
- [[../../03 Engineering/Service and Runtime Boundaries]]
