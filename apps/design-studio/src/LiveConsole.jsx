import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  Activity,
  ArrowLeft,
  ArrowRight,
  Check,
  ChevronRight,
  Clock3,
  Expand,
  ExternalLink,
  Headphones,
  House,
  Info,
  Music2,
  Pause,
  Play,
  Radio,
  RotateCcw,
  SlidersHorizontal,
  Square,
  X,
} from "lucide-react";
import { createRun, makeSnapshot, outputValue, reduceRun, scriptSegments } from "./live-model";
import { useSharedState } from "./shared-state";
import { RigSurface, SelectionInspector } from "./rig";
import { Dialog } from "./components";
import "./live.css";
import "./live-zones.css";

const deskZones = {
  playback: "Script / playback timeline",
  stage: "Stage / fixtures",
  programmer: "Selected / cue inspector",
  groups: "Group masters",
  midi: "Band / MIDI input",
  transport: "Live transport",
};

const time = (n) =>
  `${String(Math.floor(n / 60)).padStart(2, "0")}:${String(n % 60).padStart(2, "0")}`;
export default function LiveConsole({
  data,
  venue,
  showName,
  popout = false,
  rehearsal = false,
  connected = true,
  onEdit,
  update,
}) {
  const draft = useMemo(() => makeSnapshot(data, venue), [data, venue]);
  const key = `vv-live-v2:${encodeURIComponent(showName)}:${encodeURIComponent(venue)}:${rehearsal ? "rehearsal" : "live"}`;
  const [run, setRun] = useSharedState(key, createRun(draft));
  const [activeZone, setActiveZone] = useState(null);
  const markZone = (event) => {
    const zone = event.target.closest?.("[data-desk-zone]")?.dataset.deskZone;
    if (zone) setActiveZone(zone);
  };
  const zoneProps = (zone) => ({
    "data-desk-zone": zone,
    "data-zone-active": activeZone === zone,
    "aria-label": deskZones[zone],
  });
  const send = (action) => setRun((current) => reduceRun(current, action));
  const sendRef = useRef(send);
  sendRef.current = send;
  const [ids, setIds] = useState([]),
    [inspected, setInspected] = useState(null),
    [inspectTab, setInspectTab] = useState("selection"),
    [confirm, setConfirm] = useState(null),
    [midiAccess, setMidiAccess] = useState(null),
    [inputId, setInputId] = useState(""),
    [ports, setPorts] = useState([]),
    [midiStatus, setMidiStatus] = useState("No physical input connected"),
    [wake, setWake] = useState("Sleep protection off"),
    [mapping, setMapping] = useState(null);
  const wakeRef = useRef(null),
    wakeWanted = useRef(false);
  const timelineRef = useRef(null);
  useEffect(() => {
    const timeline = timelineRef.current;
    const activeCard = timeline?.querySelector(".desk-cue-row.active");
    if (!activeCard) return;
    const track = timeline.getBoundingClientRect();
    const card = activeCard.getBoundingClientRect();
    if (card.top < track.top) timeline.scrollTop -= track.top - card.top + 8;
    else if (card.bottom > track.bottom) timeline.scrollTop += card.bottom - track.bottom + 8;
  }, [run.activeId, run.snapshot.script]);
  const pending = JSON.stringify(draft) !== JSON.stringify(run.snapshot);
  const entries = run.snapshot.script,
    fixtures = run.snapshot.fixtures;
  const active = entries.find((e) => e.entryId === run.activeId);
  const activeIndex = entries.findIndex((e) => e.entryId === run.activeId);
  const next = entries[activeIndex + 1];
  const inspect =
    entries.find((e) => e.entryId === inspected) || active || entries[0];
  const roles = [...new Set(fixtures.map((f) => f.role))];
  const groups = scriptSegments(entries);
  const output = Object.fromEntries(
    fixtures.map((f) => [f.id, outputValue(run, f)]),
  );
  const blocked = !run.armed || run.held || run.blackout || !run.connected;
  const hitCount = entries.filter((e) => run.hits[e.entryId]).length;
  useEffect(() => {
    if (pending && !run.armed)
      sendRef.current({ type: "apply-draft", snapshot: draft });
  }, [pending, draft, run.armed]);
  useEffect(() => {
    if (connected !== run.connected)
      sendRef.current({ type: "connection", value: connected });
  }, [connected, run.connected]);
  useEffect(() => {
    setIds((old) => old.filter((id) => fixtures.some((f) => f.id === id)));
  }, [fixtures]);
  useEffect(() => {
    if (!midiAccess || !inputId) return;
    let cancelled = false,
      release;
    const input = midiAccess.inputs.get(inputId);
    if (!input) return;
    if (!navigator.locks) {
      setMidiStatus("Physical MIDI requires single-receiver coordination");
      return;
    }
    navigator.locks
      .request(`${key}:midi-owner`, { ifAvailable: true }, async (lock) => {
        if (cancelled) return;
        if (!lock) {
          setMidiStatus("Another console owns this MIDI input");
          return;
        }
        setMidiStatus(`Listening · ${input.name || "MIDI device"}`);
        input.onmidimessage = (event) => {
          const bytes = Array.from(event.data),
            type = bytes[0] & 0xf0;
          if (type === 0x80 || (type === 0x90 && bytes[2] === 0)) return;
          if ([0x90, 0xb0, 0xc0].includes(type))
            sendRef.current({ type: "midi", bytes, at: Date.now() });
        };
        await new Promise((resolve) => {
          release = resolve;
          if (cancelled) resolve();
        });
        input.onmidimessage = null;
      })
      .catch(() => setMidiStatus("Could not acquire MIDI input ownership"));
    return () => {
      cancelled = true;
      release?.();
    };
  }, [midiAccess, inputId, key]);
  useEffect(() => {
    if (!midiAccess) return;
    const changed = () => {
      setPorts([...midiAccess.inputs.values()]);
      const input = midiAccess.inputs.get(inputId);
      if (inputId && (!input || input.state === "disconnected")) {
        setInputId("");
        setMidiStatus("MIDI device disconnected · choose an input to resume");
        sendRef.current({ type: "midi-enabled", value: false });
      }
    };
    midiAccess.addEventListener("statechange", changed);
    return () => midiAccess.removeEventListener("statechange", changed);
  }, [midiAccess, inputId]);
  async function connectMidi() {
    if (!navigator.requestMIDIAccess) {
      setMidiStatus(
        "Web MIDI unavailable · use test trigger or a production bridge",
      );
      return;
    }
    try {
      const access = await navigator.requestMIDIAccess({ sysex: false });
      setMidiAccess(access);
      const inputs = [...access.inputs.values()];
      setPorts(inputs);
      setInputId(inputs[0]?.id || "");
      setMidiStatus(
        inputs.length ? "Select input and enable MIDI" : "No MIDI inputs found",
      );
    } catch {
      setMidiStatus(
        "MIDI permission denied or unavailable · manual GO remains available",
      );
    }
  }
  async function acquireWake() {
    if (!navigator.wakeLock) {
      setWake("Wake lock unavailable in this browser");
      return;
    }
    try {
      wakeRef.current = await navigator.wakeLock.request("screen");
      setWake("Screen kept awake");
      wakeRef.current.addEventListener("release", () =>
        setWake("Wake lock released · window must stay visible"),
      );
    } catch {
      setWake("Wake lock unavailable · check device power settings");
    }
  }
  useEffect(() => {
    const visible = () => {
      if (document.visibilityState === "visible" && wakeWanted.current)
        acquireWake();
    };
    document.addEventListener("visibilitychange", visible);
    return () => {
      document.removeEventListener("visibilitychange", visible);
      wakeWanted.current = false;
      wakeRef.current?.release();
    };
  }, []);
  function pop() {
    const url = new URL(location.href);
    url.searchParams.set("screen", rehearsal ? "rehearsal" : "live");
    url.searchParams.set("popout", "1");
    url.searchParams.set("show", showName);
    url.searchParams.set("venue", venue);
    const child = window.open(
      url,
      `vv-console-${encodeURIComponent(showName + venue)}`,
      "popup,width=1500,height=1000",
    );
    if (!child)
      send({
        type: "message",
        message: "Pop-out blocked · allow popups for this local application",
      });
    else child.focus();
  }
  function choose(nextIds) {
    setIds(nextIds);
    setInspectTab("selection");
  }
  function inspectCue(entry) {
    setInspected(entry.entryId);
    setInspectTab("cue");
  }
  function testMidi() {
    const target = inspect?.midi;
    if (!target) return;
    const status =
      (target.type === "note" ? 0x90 : target.type === "cc" ? 0xb0 : 0xc0) +
      (target.channel - 1);
    send({ type: "midi", bytes: [status, target.number, 100], at: Date.now() });
  }
  const sections = (
    <>
      {groups.map(({ song, entries: songEntries }) => {
        return (
          <div className="song-block" key={songEntries[0].entryId} style={{ "--song-cues": songEntries.length }}>
            <div className="song-title">
              <Music2 size={14} />
              <span>{song}</span>
              <button
                aria-label={`Restart ${song}`}
                disabled={blocked}
                onClick={() =>
                  setConfirm({ kind: "restart", entry: songEntries[0] })
                }
              >
                <RotateCcw size={14} />
              </button>
            </div>
            {songEntries.map((entry) => {
              const hit = run.hits[entry.entryId],
                isActive = run.activeId === entry.entryId;
              return (
                <button
                  key={entry.entryId}
                  className={`desk-cue-row ${isActive ? "active" : ""} ${hit ? "fired" : ""} ${inspect?.entryId === entry.entryId ? "inspected" : ""}`}
                  aria-label={`Inspect ${entry.id} ${entry.name}`}
                  aria-pressed={inspect?.entryId === entry.entryId}
                  onClick={() => inspectCue(entry)}
                >
                  <span className="live-slot-number" aria-label={`Slot ${entries.findIndex((item) => item.entryId === entry.entryId) + 1}`}>
                    {String(entries.findIndex((item) => item.entryId === entry.entryId) + 1).padStart(2, "0")}
                  </span>
                  <span className="cue-check">
                    {isActive ? (
                      <Radio size={15} />
                    ) : hit ? (
                      <Check size={15} />
                    ) : (
                      <span />
                    )}
                  </span>
                  <span className="cue-id">{entry.id}</span>
                  <span className="cue-row-name">
                    <strong>{entry.name}</strong>
                    <small>
                      {isActive
                        ? "Active"
                        : hit
                          ? `Called · ${hit.source}`
                          : entry.midi
                            ? `MIDI ${entry.midi.type} ${entry.midi.number} · ch ${entry.midi.channel}`
                            : "Manual Next"}
                    </small>
                  </span>
                  <time>{time(entry.offset)}</time>
                </button>
              );
            })}
          </div>
        );
      })}
    </>
  );
  return (
    <div
      className={`lighting-desk ${popout ? "detached-desk" : ""}`}
      onPointerDownCapture={markZone}
      onFocusCapture={markZone}
    >
      <header className="desk-heading">
        <div>
          <div className="desk-eyebrow">
            <Headphones size={13} />
            {rehearsal ? "PROGRAMMING / REHEARSAL" : "LIVE / FRONT OF HOUSE"}
            <span className="desk-zone-readout" data-zone={activeZone}>
              {activeZone ? `Control focus · ${deskZones[activeZone]}` : "Tap a section to control"}
            </span>
          </div>
          <h1>
            {venue}
            <span> / {rehearsal ? "Rehearsal" : "Live console"}</span>
          </h1>
          <p>
            {showName} <span>·</span> Main performance <span>·</span> Pass{" "}
            {run.pass}
          </p>
        </div>
        <div className="desk-window-actions">
          <span className="simulation-label">SIMULATION · NO DMX OUTPUT</span>
          {!popout && (
            <button onClick={pop}>
              <ExternalLink size={16} />
              Pop out console
            </button>
          )}
          <button
            onClick={() => {
              if (wakeWanted.current) {
                wakeWanted.current = false;
                wakeRef.current?.release();
                setWake("Sleep protection off");
              } else {
                wakeWanted.current = true;
                acquireWake();
              }
            }}
          >
            <Expand size={15} />
            {wake.startsWith("Screen") ? "Kept awake" : "Keep awake"}
          </button>
        </div>
      </header>
      <div className="desk-status">
        <span className={run.connected ? "connected" : "lost"}>
          <i />
          {run.connected
            ? "Demo bridge online"
            : "Bridge lost · output unknown"}
        </span>
        <span>
          <Activity size={13} />
          Same-browser windows synchronized
        </span>
        <span>{wake}</span>
        <button onClick={() => onEdit("preflight")}>
          Preflight
          <ChevronRight size={14} />
        </button>
      </div>
      {pending && (
        <div className="live-update-banner" role="status">
          <span>
            <b>Venue edits available.</b> Review applied changes for future
            cues; current output is retained.
          </span>
          <button onClick={() => setConfirm({ kind: "update" })}>
            Review & apply
          </button>
        </div>
      )}
      <div className="desk-workspace">
        <section className="desk-panel stage-panel" {...zoneProps("stage")}>
          <div className="desk-panel-title">
            <h2>Stage / fixtures</h2>
            <span>Universe 1 · preview</span>
          </div>
          <RigSurface
            fixtures={fixtures}
            ids={ids}
            onSelect={choose}
            values={output}
          />
          <div className="submasters" role="group" {...zoneProps("groups")}>
            <div className="submaster-heading">
              <h3>Group masters</h3>
              <span>Intensity trim · 0–100%</span>
            </div>
            <div className="submaster-grid">
              {roles.map((role) => (
                <label key={role}>
                  <span>
                    {role}
                    <b>{run.groupMasters[role] ?? 100}%</b>
                  </span>
                  <input
                    type="range"
                    min="0"
                    max="100"
                    aria-label={`${role} master`}
                    value={run.groupMasters[role] ?? 100}
                    onChange={(e) =>
                      send({ type: "group", role, value: e.target.value })
                    }
                  />
                  <button
                    onClick={() =>
                      choose(
                        fixtures
                          .filter((f) => f.role === role)
                          .map((f) => f.id),
                      )
                    }
                  >
                    Select group
                  </button>
                </label>
              ))}
            </div>
          </div>
        </section>
        <aside className="desk-panel desk-inspector" {...zoneProps("programmer")}>
          <div className="desk-inspector-tabs">
            <button
              aria-pressed={inspectTab === "selection"}
              onClick={() => setInspectTab("selection")}
            >
              Selected <span>{ids.length}</span>
            </button>
            <button
              aria-pressed={inspectTab === "cue"}
              onClick={() => setInspectTab("cue")}
            >
              Cue details
            </button>
          </div>
          {inspectTab === "selection" ? (
            <SelectionInspector
              live
              fixtures={fixtures}
              ids={ids}
              values={output}
              presets={run.snapshot.presets}
              onChange={(values, nudge) =>
                send({ type: "programmer", ids, values, nudge })
              }
              onRelease={() => send({ type: "release", ids })}
            />
          ) : (
            <div className="cue-details">
              <div className="cue-detail-title">
                <span>INSPECTING · DOES NOT FIRE</span>
                <h3>
                  {inspect?.id} · {inspect?.name}
                </h3>
                <p>
                  {inspect?.song} · +{time(inspect?.offset || 0)} · fade{" "}
                  {inspect?.fade}s (metadata)
                </p>
              </div>
              <h4>Reactive targets</h4>
              {inspect?.assignments.map((a, i) => {
                const targets = fixtures.filter(
                  (f) => a.role === f.role || a.fixtureId === f.id,
                );
                return (
                  <button
                    className="assignment-target"
                    key={i}
                    onClick={() => choose(targets.map((f) => f.id))}
                  >
                    <SlidersHorizontal size={16} />
                    <span>
                      <strong>{a.role || a.fixtureId}</strong>
                      <small>
                        {a.preset} · {targets.length} fixtures
                      </small>
                      <em>{targets.map((f) => f.id).join(", ")}</em>
                    </span>
                    <ChevronRight size={15} />
                  </button>
                );
              })}
              <div className="cue-trigger-detail">
                <span>Band MIDI trigger</span>
                <strong>
                  {inspect?.midi.type.toUpperCase()} {inspect?.midi.number} /
                  channel {inspect?.midi.channel}
                </strong>
                <small>
                  Targets this script occurrence. Note Off and zero velocity
                  never fire.
                </small>
                <button
                  onClick={() =>
                    setMapping({
                      ...inspect.midi,
                      entryId: inspect.entryId,
                      name: inspect.name,
                    })
                  }
                >
                  Edit MIDI mapping
                </button>
              </div>
              <div className="cue-detail-actions">
                <button
                  disabled={blocked}
                  onClick={() => setConfirm({ kind: "call", entry: inspect })}
                >
                  <Play size={15} />
                  Go to cue
                </button>
                <button
                  disabled={blocked}
                  onClick={() =>
                    setConfirm({ kind: "restart", entry: inspect })
                  }
                >
                  <RotateCcw size={15} />
                  Restart from here
                </button>
              </div>
            </div>
          )}
        </aside>
      </div>
      <section className="midi-strip" {...zoneProps("midi")}>
        <div>
          <Music2 size={19} />
          <span>
            <strong>Band / MIDI input</strong>
            <small>{midiStatus}</small>
          </span>
        </div>
        <button onClick={connectMidi}>
          {midiAccess ? "Refresh MIDI devices" : "Connect MIDI device"}
        </button>
        {ports.length > 0 && (
          <select
            aria-label="MIDI input device"
            value={inputId}
            onChange={(e) => setInputId(e.target.value)}
          >
            <option value="">No receiver</option>
            {ports.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name || p.id}
              </option>
            ))}
          </select>
        )}
        <label className="midi-toggle">
          <input
            type="checkbox"
            aria-label="Enable MIDI triggers"
            checked={run.midiEnabled}
            onChange={(e) =>
              send({ type: "midi-enabled", value: e.target.checked })
            }
          />
          MIDI {run.midiEnabled ? "enabled" : "disabled"}
        </label>
        <button disabled={!run.midiEnabled || blocked} onClick={testMidi}>
          Test {inspect?.id} trigger
        </button>
        <span className="midi-help">
          Cue input pauses on Hold. Hardware input is optional.
        </span>
      </section>
      <section className="desk-panel playback-dock" {...zoneProps("playback")}>
        <div className="desk-panel-title">
          <h2><Clock3 size={15} /> Script / playback timeline</h2>
          <span>{hitCount}/{entries.length} called · Tap a slot to inspect · Scroll for all cues</span>
          <button className="edit-script-button" onClick={() => onEdit("script-editor")}>Edit running order</button>
        </div>
        <div className="playback-summary">
          <div><span>CURRENT</span><h2>{active ? `${active.id} · ${active.name}` : "Standby"}</h2></div>
          <div><span>NEXT</span><strong>{next ? `${next.id} · ${next.name}` : "End of script"}</strong></div>
          <strong className="playback-state">{!run.connected ? "Disconnected" : !run.armed ? "Disarmed" : run.blackout ? "Blackout · cue input paused" : run.held ? "HELD · cue input paused" : "Following cue input"}</strong>
        </div>
        <div className="script-cue-timeline" ref={timelineRef} aria-label="All script cues">{sections}</div>
      <div className="desk-transport" role="group" {...zoneProps("transport")}>
        <div className="desk-arm">
          <span className={run.armed ? "armed" : "disarmed"}>
            {run.armed ? "ARMED · SIMULATION" : "DISARMED"}
          </span>
          <button
            disabled={!run.connected}
            onClick={() => send({ type: "arm" })}
          >
            {run.armed ? "Disarm" : "Arm simulation"}
          </button>
        </div>
        <label className="grand-master">
          <span>
            Grand master <strong>{run.master}%</strong>
          </span>
          <input
            aria-label="Grand master"
            type="range"
            min="0"
            max="100"
            value={run.master}
            onChange={(e) => send({ type: "master", value: e.target.value })}
          />
        </label>
        <button
          className="desk-clear"
          onClick={() => send({ type: "release" })}
        >
          <RotateCcw size={17} />
          Release manual<span>{Object.keys(run.programmer).length}</span>
        </button>
        <button
          className="transport-primary desk-back"
          disabled={blocked || activeIndex < 1}
          onClick={() => send({ type: "back" })}
        >
          <ArrowLeft size={18} />
          Back
        </button>
        <button
          className="transport-primary desk-next"
          disabled={blocked || !next}
          onClick={() => send({ type: "next" })}
        >
          Next <ArrowRight size={22} />
        </button>
        <button
          disabled={!run.armed}
          className={`transport-primary desk-hold ${run.held ? "is-held" : ""}`}
          aria-pressed={run.held}
          onClick={() => send({ type: "hold" })}
        >
          {run.held ? <Play size={22} /> : <Pause size={22} />}
          {run.held ? "Play" : "Hold"}
        </button>
        <div className="transport-secondary">
        <button
          className={`blackout-button ${run.blackout ? "latched" : ""}`}
          onClick={() => send({ type: "blackout" })}
        >
          <Square size={16} />
          {run.blackout ? "Restore output" : "Blackout"}
        </button>
        <button
          className="house-button"
          title="Call the configured House open cue; moves script position"
          disabled={blocked || !entries.some((entry) => entry.entryId === run.snapshot.houseEntryId)}
          onClick={() => send({ type: "house" })}
        >
          <House size={16} /> House
        </button>
        </div>
      </div>
      </section>
      <div className="desk-message" role="status">
        <Info size={13} />
        {run.lastMessage}
        <span>Manual → cue → group trim → grand master → blackout</span>
      </div>
      {mapping && (
        <Dialog
          title={"MIDI mapping · " + mapping.name}
          onClose={() => setMapping(null)}
        >
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const venueConfig = data.venueProgramming?.[venue] || {};
              update({
                venueProgramming: {
                  ...data.venueProgramming,
                  [venue]: {
                    ...venueConfig,
                    midiMappings: {
                      ...venueConfig.midiMappings,
                      [mapping.entryId]: {
                        type: mapping.type,
                        channel: mapping.channel,
                        number: mapping.number,
                      },
                    },
                  },
                },
              });
              setMapping(null);
            }}
          >
            <label className="field">
              Message type
              <select
                aria-label="MIDI message type"
                value={mapping.type}
                onChange={(e) =>
                  setMapping({ ...mapping, type: e.target.value })
                }
              >
                <option value="note">Note On</option>
                <option value="cc">Control Change (nonzero)</option>
                <option value="program">Program Change</option>
              </select>
            </label>
            <label className="field">
              Channel (1–16)
              <input
                type="number"
                aria-label="MIDI channel"
                required
                min="1"
                max="16"
                value={mapping.channel}
                onChange={(e) =>
                  setMapping({ ...mapping, channel: Number(e.target.value) })
                }
              />
            </label>
            <label className="field">
              Number (0–127)
              <input
                type="number"
                aria-label="MIDI number"
                required
                min="0"
                max="127"
                value={mapping.number}
                onChange={(e) =>
                  setMapping({ ...mapping, number: Number(e.target.value) })
                }
              />
            </label>
            <p>
              Stored for {venue}. When armed, review and apply the update before
              using the new mapping. MIDI clock and timecode are not
              interpreted.
            </p>
            <div className="form-footer">
              <button
                type="button"
                className="button"
                onClick={() => setMapping(null)}
              >
                Cancel
              </button>
              <button type="submit" className="button primary">
                Save venue MIDI mapping
              </button>
            </div>
          </form>
        </Dialog>
      )}
      {confirm && (
        <Dialog
          title={
            confirm.kind === "update"
              ? "Apply venue edits"
              : confirm.kind === "restart"
                ? "Restart script from this cue"
                : "Call selected cue"
          }
          onClose={() => setConfirm(null)}
        >
          {confirm.kind === "update" ? (
            <>
              <p>
                Apply {draft.script.length} script entries and updated preset
                values to future cue calls. Active cue values and manual
                adjustments remain untouched.
              </p>
              <p>
                Fixture/patch changes or removal of the active entry require
                disarming.
              </p>
            </>
          ) : (
            <>
              <p>
                <strong>
                  {confirm.entry.id} · {confirm.entry.name}
                </strong>{" "}
                — {confirm.entry.song}, +{time(confirm.entry.offset)}.
              </p>
              <p>
                {confirm.kind === "restart"
                  ? "Reapply this cue, clear progress from here onward, and begin a new pass. Earlier call history is retained, and subsequent MIDI cues may fire again."
                  : "Call this cue now and move the playhead to its script entry. Skipped cues are not marked called."}
              </p>
              <p>
                Manual overrides remain until released. Output transitions are
                simulated as immediate values in this prototype.
              </p>
            </>
          )}
          <div className="form-footer">
            <button className="button" onClick={() => setConfirm(null)}>
              Cancel
            </button>
            <button
              className="button primary"
              onClick={() => {
                send(
                  confirm.kind === "update"
                    ? { type: "apply-draft", snapshot: draft }
                    : { type: confirm.kind, entryId: confirm.entry.entryId },
                );
                setConfirm(null);
              }}
            >
              {confirm.kind === "update"
                ? "Apply to future cues"
                : confirm.kind === "restart"
                  ? "Restart & call cue"
                  : "Call cue now"}
            </button>
          </div>
        </Dialog>
      )}
    </div>
  );
}
