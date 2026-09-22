---
type: feature
id: F17
status: specified-and-prototyped
owner: product-and-engineering
updated: 2026-09-20
---

# F17 — Script transport and MIDI triggers

## Confirmed direction

A band's MIDI track can trigger lighting cues. Called cues are marked on the script and move its visible progress forward. Operators can inspect a cue's reactive fixtures/groups, directly call cues, and return to an earlier point such as the start of a song so the sequence can run again.

## Data contract

Extend script entries with stable entry ID, song/segment reference, expected relative offset, and trigger mappings. A cue definition is still reusable; triggering targets a particular script occurrence. Store venue trigger adaptations separately from show defaults.

Run events include session ID, snapshot revision, script entry, source (operator/MIDI/restart), source event ID, actual timestamp, playback pass, and acknowledgement. Maintain current active entry, expected next entry, hit markers for the current pass, skipped entries, and an append-only historical call log.

The prototype's editable song labels are a simplified grouping key; production uses stable song IDs so renames and repeated songs remain unambiguous.

## Inspect versus activate

The script and timeline share one bottom playback box containing all script occurrences grouped by song. Tapping a cue card opens its detail panel without changing output. Show target fixture roles/instances, assigned presets, resolved target IDs, transition metadata, and MIDI mapping. Selecting a target group changes the stage selection only. Next activates the next script entry (the former GO action). Back immediately recalls the previous occurrence. Go to cue requires an explicit call action; a jump must not mark skipped entries as called.

## Restart semantics

Restart from song or a selected cue explicitly reapplies that entry's state, begins a new playback pass, and clears current-pass markers from that entry onward. Earlier markers remain; earlier historical events are retained. Following cues become eligible for MIDI and operator activation again. Manual programmer values persist unless separately released. The production runtime must cancel prior scheduled follows and reject late events from the previous playback generation.

Back now immediately uses restart semantics for the previous script entry, without a confirmation dialog. Explicit song/point restarts still require review. Back is unavailable at the first entry and Next at the last; neither wraps. Hold/blackout/disconnect gate progression and direct calls. At the final entry, retain the final state until another explicit action.

## Hold, Play, and secondary controls

Hold keeps the current cue active, pauses cue intake/advancement, and changes the button to Play. Play only releases this gate; it does not itself advance the script. Incoming MIDI while held is discarded, not queued for a burst on resume. Manual fixture and master adjustments remain available. Production follow timers must suspend while held and use an explicit resume policy; timed follows are not implemented by this prototype.

Blackout and House are less visually prominent than Back, Next, and Hold/Play, while retaining touch target sizes and clear active state. Blackout does not move the playhead. The current House shortcut restarts from the configured venue `houseEntryId`, reapplying that cue and resetting later replay markers; the demo defaults to its named “House open” entry. It respects arm/hold/blackout/connection gates. No mapping means disabled. This proposed House behavior is a cue shortcut, not an independently controllable house circuit; production needs a stable entry binding, explicit configuration UI, permission checks, and an acknowledged/audited House command. House preserves manual programmer values and does not bypass masters or blackout.

## MIDI input

Support mapping input device, channel, message type, number/value filter, and target script occurrence. The prototype accepts Note On with positive velocity, nonzero Control Change, and Program Change. Note Off and zero-velocity Note On do not fire. The displayed numeric mapping is the raw 0–127 number, avoiding octave-name ambiguity. Channels are shown as 1–16.

MIDI input must be explicitly enabled in an armed session. Provide device permission/unavailable/disconnected states, message diagnostics, learn/mapping tools, and manual Next fallback. Reconnecting a device does not replay buffered cues. One runtime input authority handles a device so opening two consoles cannot double-fire the same event.

MIDI clock, MIDI timecode (MTC), MIDI Show Control, audio-following, and arbitrary MIDI file import are distinct capabilities, not implied by Note/CC/Program mappings. The timeline is currently cue-driven with expected song offsets, not a continuous synchronized clock. Their exact support requires a timing/transport R&D decision.

## Cross-layer responsibilities

- UI: unified bottom script timeline with every occurrence, song groups, current/next cue, hit marks, primary Back/Next/Hold–Play, secondary Blackout/House, inspectable targets, direct call/restart confirmation, editable venue MIDI mappings, input enable, and test trigger.
- API/storage: version script and mapping changes, validate trigger ranges, preserve stable occurrence IDs, retain audit events by run/pass, and expose actual versus expected timestamps.
- Runtime: normalize device messages, apply channel/value filters, deduplicate source events, gate commands, serialize operator/MIDI races, invalidate old restart generations, and acknowledge actual applications.
- Local bridge: production MIDI reception and cue scheduling remain active independently of browser throttling; credentials and input ownership are scoped to the show/venue session.

## Acceptance and prototype limits

Verified with synthetic events: manual and MIDI calls update the same playhead; inspection does not call; repeats retain identity; skipped cues remain unmarked; song restart enables later cues again; hold/blackout/disconnect block progression. The prototype's receiver uses Web MIDI when supported and permitted, and same-browser input ownership uses Web Locks. Physical MIDI hardware is not validated. Full packet deduplication, CC edge policies, timestamp scheduling, bridge failover, and timecode seek need production implementation. The test-trigger button works without physical devices.

Related: [[F11 - Cues and state transitions]], [[F12 - Scripts and running order]], [[F16 - Workflow modes and live programmer]], [[F18 - Persistent console and live updates]].
