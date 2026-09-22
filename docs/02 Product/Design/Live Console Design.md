---
type: design
status: interactive-prototype
updated: 2026-09-21
---

# Live Console Design

## Design revision 05

The console uses an interactive stage and group masters on the left, with a selected/cue inspector on the right. The script and timeline are merged into one bottom playback box, containing every cue occurrence in vertical numbered slots grouped by song, current/next readouts, and transport controls. There is no duplicate left-hand script list. Cue slots scroll vertically when needed and track the active cue without reloading; display positions are separate from persistent cue and entry IDs. Edit running order opens the script editor with mouse/touch drag handles, target highlights, and keyboard/up-down alternatives. Live slots themselves cannot be dragged or reordered. The MIDI strip sits above this box. In the wide detached window, workspace chrome disappears and tall panels scroll internally so playback remains visible. Narrow screens stack panels and place the complete playback box in document flow; it is not pinned over other controls. The primary operating target remains a landscape touch monitor.

## Familiar operating vocabulary

Use explicit selection, programmer, release, current/next cue, Next, Back, Hold/Play, grand master, group master, and blackout concepts. Selecting and inspecting are independent of activation. Next is the console's sequential GO action. Our proposed programmer stays above cue playback until released; our group masters are intensity trims. These policies are ours, not a claim of exact compatibility with any desk.

Relevant precedents:

- [ETC Eos — Selected Cue](https://www.etcconnect.com/WebDocs/Controls/EosFamilyOnlineHelp/en/Content/13_Cue_Playback/Selected_Cue.htm): selected/editing cue can differ from live playback. This informs the separate inspected cue and active cue.
- [MA Lighting — Programmer](https://help2.malighting.com/grandMA3/2.4/HTML/operate_programmer.html): manual attribute control and selection are distinct concepts. This informs the selected detail panel and explicit release controls.
- [ETC Eos — Go To Cue](https://www.etcconnect.com/WebDocs/Controls/EosFamilyOnlineHelp/en/Content/13_Cue_Playback/%5BGo_To_Cue%5D.htm): direct cue activation is a distinct live action. Venue Volume adds reviewed script restart semantics around it.

## Workflow colors

Violet identifies pre-programming, amber identifies venue programming, and teal identifies live operation. Mode text and step numbers remain visible, so color is not the only signal. Blackout uses a separate latched red treatment. Manually adjusted fixtures carry an amber marker and selected fixtures a ring/checkmark.

## Console section contrast

Distinct tinted surfaces, saturated title bands, and colored top edges make control areas recognizable without reading every label. These are local functional colors, not changes to workflow mode or output state.

| Section | Color |
| --- | --- |
| Script / playback timeline | Blue |
| Stage / fixtures | Cyan |
| Selected / cue inspector | Amber |
| Group masters | Lime |
| Band / MIDI input | Violet |
| Live transport | Teal |

Pointer/touch interaction or keyboard focus adds a stronger outline to exactly one section and updates a textual **Control focus** indicator in the console heading. Nested group-master interactions highlight group masters, not the enclosing stage. This is local window presentation state, not control ownership, arming, cue activation, or a shared runtime command. Keyboard controls retain a separate white focus outline. No animation or flashing is used; red remains reserved for blackout/fault semantics. Wireframes retain section labels and a monochrome active outline.

Acceptance: all six functional surfaces are visually distinct; selected/active cues and fixture colors retain their meaning; touch and keyboard update the active-section indicator; detached, embedded, and narrow layouts preserve access to transport. Low-light FOH and color-vision usability still require operator validation.

## Unified playback controls

- **Back / Next:** large primary controls immediately call the previous/next script occurrence. Back clears replay eligibility from the recalled entry onward, retaining history. Neither wraps at script boundaries. Inspecting a cue card never moves the playhead.
- **Hold / Play:** Hold retains the active cue, blocks advancement from Next/Back/direct calls/MIDI, and changes to Play. Play resumes intake without calling a cue itself or replaying triggers received while held. Live manual adjustments remain available. Interpret the requested “place” button as Play.
- **Blackout / House:** secondary 44px-minimum controls with subdued inactive styling. Latched blackout still has an explicit red state. House currently restarts from the venue's configured house script entry (the demo's “House open” cue), moving the playhead and making later cues eligible again. It is not an independent house-light circuit toggle. House is disabled while held, blacked out, disarmed, disconnected, or unmapped. Production needs an explicit venue house-entry binding editor; never guess real house circuits from fixture order.

## Essential interactions

1. Select fixtures by tapping the rig, choose a role group, or select the whole venue.
2. Adjust intensity, nudge each selected value, pick a color or preset, or adjust position when supported.
3. Release selected/all manual values to return control to the active cue.
4. Inspect a cue to see its reactive roles, fixture IDs, presets, and trigger. Select those targets directly.
5. Call via Next/Back, reviewed Go to cue, or MIDI input. The active/next state, timeline, and checkmarks update together.
6. Restart a song or selected entry; confirm the starting state and begin a new pass with subsequent cues eligible again.
7. Pop out the console, edit the venue in the original window, review the resulting draft update, and keep operating without reload.

Expected offsets are shown within each song; timeline spacing currently represents ordered cue moments, not duration. A clock/timecode-synchronized view is a separate future transport feature. Fade values are metadata in this prototype; simulated output changes immediately.

## Technical references and limits

- [Broadcast Channel API](https://developer.mozilla.org/en-US/docs/Web/API/Broadcast_Channel_API) provides same-origin window communication; it does not provide application conflict/authority semantics.
- [Web MIDI API](https://developer.mozilla.org/en-US/docs/Web/API/Web_MIDI_API) requires supported browser capabilities, secure context and user permission. The prototype requests input access only after Connect MIDI device.
- [Screen Wake Lock API](https://developer.mozilla.org/en-US/docs/Web/API/Screen_Wake_Lock_API) can be released by the browser and does not provide an OS always-on-top guarantee.

The production architecture remains a local runtime/bridge with authenticated console subscriptions. These browser tools make the interaction testable; they are not substitutes for timing, device, or authority validation.

## Feature links

- [[../Features/F16 - Workflow modes and live programmer]]
- [[../Features/F17 - Script transport and MIDI triggers]]
- [[../Features/F18 - Persistent console and live updates]]
- [[Interaction Coverage]]
