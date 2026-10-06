import React, { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import {
  Activity,
  ArrowLeft,
  ArrowRight,
  ArrowUpRight,
  Box,
  Building2,
  Check,
  CheckCircle2,
  ChevronDown,
  ChevronRight,
  CircleHelp,
  ClipboardCheck,
  Copy,
  Download,
  File,
  FileText,
  Folder,
  Gauge,
  Grid2X2,
  Layers,
  Lightbulb,
  ListMusic,
  MapPin,
  Monitor,
  MoreHorizontal,
  Network,
  Pause,
  Pencil,
  Play,
  Plus,
  Radio,
  RotateCcw,
  Search,
  Settings,
  Shield,
  SlidersHorizontal,
  Sparkles,
  Square,
  Trash2,
  Upload,
  Users,
  WifiOff,
  X,
  Zap,
} from "lucide-react";
import { screens, fixtureRows, presetRows, cueRows } from "./catalog";
import { patchErrors, resolveValue } from "./model";
import {
  Badge,
  Button,
  Dialog,
  Empty,
  Field,
  FormFooter,
  Metric,
  Panel,
  Progress,
  RowLink,
  SearchBox,
  Stage,
  Table,
} from "./components";
import "./styles.css";
import CuePaletteAssignments from "./CuePaletteAssignments";
import PaletteWorkbench from "./PaletteWorkbench";
import { baselinePalettes } from "./palettes-phasers";
import LiveConsole from "./LiveConsole";
import Workspace from "./Workspace";
import ScriptSlots from "./ScriptSlots";
import { useSharedState } from "./shared-state";
import { createRun, makeSnapshot } from "./live-model";
import { StandaloneMovieUpload } from "./VenueMovies";

const initial = {
  showName: "Afterglow · Fall tour",
  shows: ["Afterglow · Fall tour", "Common ground", "The midnight sessions"],
  venues: ["The Glasshouse", "Mercury Hall", "Northside Theater"],
  templates: ["Touring rig", "Intimate room", "Festival stage"],
  presets: [...presetRows, ...baselinePalettes],
  fixtures: fixtureRows,
  script: cueRows.map((c, i) => ({ ...c, entryId: `entry-${i}` })),
  intensity: 75,
  venueOverrides: { "The Glasshouse": 60 },
  members: ["Alex Morgan", "Jamie Park", "Sam Rivera"],
  uploads: [],
};
function load() {
  try {
    const stored = JSON.parse(localStorage.getItem("vv-design-v1") || "{}");
    const presets = stored.presets ?? initial.presets;
    return { ...initial, ...stored, presets: [...presets, ...baselinePalettes.filter(p => !presets.some(existing => existing.name === p.name))] };
  } catch {
    return initial;
  }
}
const urlParams = () => new URLSearchParams(location.search);
function App({ embeddedRoute, onNavigate, context }) {
  const [storedData, setData] = useSharedState(
      context ? `vv-programming-preview:${context.id}` : "vv-design-v1",
      context
        ? {
            ...initial,
            showName: context.name,
            venues: [context.venue],
            venueOverrides: {},
          }
        : load(),
    ),
    [route, setRoute] = useState(
      embeddedRoute || urlParams().get("screen") || "overview",
    ),
    [mode, setMode] = useState(urlParams().get("mode") || "hifi"),
    [scenario, setScenario] = useState(urlParams().get("state") || "ready");
  const [gallery, setGallery] = useState(false),
    [query, setQuery] = useState(""),
    [modal, setModal] = useState(null),
    [toast, setToast] = useState(""),
    [scope, setScope] = useState("show"),
    [venue, setVenue] = useState(
      context?.venue || urlParams().get("venue") || "The Glasshouse",
    ),
    [selected, setSelected] = useState(0),
    [connected, setConnected] = useSharedState("vv-demo-connected", true),
    [dirty, setDirty] = useState(false);
  const existingPalettes = storedData.presets ?? initial.presets;
  const seededData = { ...storedData, presets: [...existingPalettes, ...baselinePalettes.filter(p => !existingPalettes.some(existing => existing.name === p.name))] };
  const data = context ? { ...seededData, fixtures: context.fixtures } : seededData;
  const screen = screens.find((s) => s.id === route) || screens[4];
  const [liveRun, setLiveRun] = useSharedState(
    `vv-live-v2:${encodeURIComponent(context?.id || urlParams().get("show") || data.showName)}:${encodeURIComponent(venue)}:live`,
    createRun(makeSnapshot(data, venue)),
  );
  const blackout = liveRun.blackout;
  const setArmed = (value) =>
    setLiveRun((previous) => ({ ...previous, armed: value }));
  useEffect(() => {
    if (!toast) return;
    const t = setTimeout(() => setToast(""), 4000);
    return () => clearTimeout(t);
  }, [toast]);
  function go(id) {
    if (embeddedRoute) {
      onNavigate(id);
      return;
    }
    if (dirty) {
      setModal({ kind: "unsaved", target: id });
      return;
    }
    setRoute(id);
    setQuery("");
    setScenario("ready");
    setGallery(false);
    window.scrollTo(0, 0);
  }
  function update(values) {
    return setData((d) => ({ ...d, ...values }));
  }
  function notify(message) {
    setToast(message);
  }
  function save() {
    setDirty(false);
    notify("Saved in this browser · prototype only");
  }
  const action = (label, id, Icon = Plus) => (
    <Button primary onClick={() => go(id)}>
      <Icon size={16} />
      {label}
    </Button>
  );
  const create = (kind, label) => (
    <Button primary onClick={() => setModal({ kind })}>
      <Plus size={16} />
      {label}
    </Button>
  );
  const editLink = (label, id) => (
    <button className="text-link" onClick={() => go(id)}>
      {label}
      <ArrowUpRight size={13} />
    </button>
  );
  const matching = (items, key = "name") =>
    items.filter((x) =>
      (typeof x === "string" ? x : x[key])
        .toLowerCase()
        .includes(query.toLowerCase()),
    );
  const issues = patchErrors(data.fixtures);
  const venueOverride = data.venueOverrides[venue];
  const source = resolveValue(
    data.intensity,
    scope === "venue" ? venueOverride : undefined,
  );
  const setVenueOverride = (value) =>
    update({ venueOverrides: { ...data.venueOverrides, [venue]: value } });
  const tabs = (items) => (
    <div className="tabs">
      {items.map(([title, id]) => (
        <button
          key={id}
          className={route === id ? "active" : ""}
          onClick={() => go(id)}
        >
          {title}
        </button>
      ))}
    </div>
  );
  const scopeBar = (
    <div className="scopebar">
      <span>
        <Layers size={15} /> Editing scope
      </span>
      <div className="segmented">
        <button
          className={scope === "show" ? "active" : ""}
          onClick={() => setScope("show")}
        >
          Show defaults
        </button>
        <button
          className={scope === "venue" ? "active" : ""}
          onClick={() => setScope("venue")}
        >
          {venue}
        </button>
      </div>
      <small>
        {scope === "show"
          ? "Inherited by all venues unless overridden"
          : "Changes apply to this venue only"}
      </small>
    </div>
  );
  const header = (title, description, actions) => (
    <div className="page-heading">
      <div>
        <div className="eyebrow">
          {screen.section.toUpperCase()} /{" "}
          {route === "overview" ? "PRODUCTION WORKSPACE" : screen.feature}
        </div>
        <h1>{title}</h1>
        <p>{description}</p>
      </div>
      <div className="heading-actions">{actions}</div>
    </div>
  );
  const cueTable = (items = data.script) => (
    <Table
      headers={["Cue", "State", "Palette", "Fade", "Scope", ""]}
      rows={items.map((c, i) => [
        <span className="mono">{c.id}</span>,
        <span className="with-dot">
          <i style={{ background: c.color }} />
          {c.name}
        </span>,
        c.preset,
        `${c.fade}.0 s`,
        <Badge tone={i === 2 ? "amber" : "neutral"}>
          {i === 2 ? "Venue override" : "Show default"}
        </Badge>,
        editLink("Edit", "cue-editor"),
      ])}
    />
  );
  const localFile = (e) => {
    const f = e.target.files?.[0];
    if (!f) return;
    update({ uploads: [...data.uploads, { name: f.name, size: f.size }] });
    notify(
      "File metadata added locally. CAD conversion and cloud storage are proposed services.",
    );
  };
  const exportShow = () => {
    const a = document.createElement("a");
    const url = URL.createObjectURL(
      new Blob([JSON.stringify(data, null, 2)], { type: "application/json" }),
    );
    a.href = url;
    a.download = "venue-volume-demo-show.json";
    a.click();
    URL.revokeObjectURL(url);
  };

  function renderScreen() {
    switch (route) {
      case "library":
        return (
          <>
            {header(
              "Know what your fixtures can do.",
              "Profiles describe capabilities; inventory represents the equipment you bring.",
              create("profile", "Add custom profile"),
            )}
            <div className="toolbar">
              <SearchBox
                value={query}
                onChange={setQuery}
                placeholder="Search fixture profiles…"
              />
              <Badge>DEMO PROFILES</Badge>
            </div>
            <Table
              headers={["Profile", "Capabilities", "Modes", "Used in show", ""]}
              rows={matching([
                {
                  name: "VV RGBW Wash",
                  cap: "Intensity · RGBW · strobe",
                  modes: "8 ch",
                },
                {
                  name: "VV Profile Spot",
                  cap: "Pan / tilt · intensity · color",
                  modes: "16 ch",
                },
                {
                  name: "VV Moving Beam",
                  cap: "Pan / tilt · color · gobo",
                  modes: "16 ch",
                },
              ]).map((p) => [
                p.name,
                p.cap,
                p.modes,
                <Badge tone="green">In use</Badge>,
                editLink("View profile", "fixture"),
              ])}
            />
            <div className="callout">
              <Lightbulb size={20} />
              <p>
                These fictional profiles are for interface review. Manufacturer
                profiles and channel maps require validation before hardware
                use.
              </p>
            </div>
          </>
        );
      case "fixture":
        return (
          <>
            {header(
              "VV RGBW Wash",
              "Fixture profile · Example manufacturer · Profile revision 01",
              <Button onClick={() => go("inventory")}>
                Use in inventory <ArrowRight size={15} />
              </Button>,
            )}
            <div className="toolbar">
              <Badge tone="amber">Demo profile · unverified</Badge>
              <Field label="DMX mode">
                <select>
                  <option>8 channel</option>
                </select>
              </Field>
            </div>
            <Table
              headers={[
                "Offset",
                "Parameter",
                "Range",
                "Default",
                "Semantic capability",
              ]}
              rows={[
                "Dimmer",
                "Red",
                "Green",
                "Blue",
                "White",
                "Strobe",
                "Macro",
                "Control",
              ].map((c, i) => [
                String(i + 1).padStart(3, "0"),
                c,
                "0–255",
                i === 0 ? "0" : "0",
                i < 5
                  ? "Continuous"
                  : i === 5
                    ? "Discrete ranges"
                    : "Manufacturer-specific",
              ])}
            />
            <Panel title="Profile validation">
              <p className="panel-copy">
                A channel map needs units, fine/coarse relationships, capability
                ranges, and safe defaults. Control channels must never inherit
                arbitrary color or intensity values.
              </p>
            </Panel>
          </>
        );
      case "presets":
        return (
          <>
            {header(
              "Good looks are worth repeating.",
              "Reusable DMX parameter palettes for fixture roles, groups, and individual fixtures.",
              create("preset", "Create palette"),
            )}
            {scopeBar}
            <div className="toolbar">
              <SearchBox
                value={query}
                onChange={setQuery}
                placeholder="Find a palette…"
              />
              <Badge>{data.presets.length} palettes</Badge>
            </div>
            <div className="three-col preset-grid">
              {matching(data.presets).map((p) => (
                <button
                  key={p.name}
                  className="preset-card"
                  onClick={() => go("preset-editor")}
                >
                  <div className="preset-visual" style={{ "--look": p.color }}>
                    <div />
                    <div />
                    <div />
                    <span>{p.type.toUpperCase()}</span>
                  </div>
                  <div className="preset-body">
                    <h2>
                      {p.name}
                      <ArrowUpRight size={16} />
                    </h2>
                    <p>
                      {p.intensity}% intensity · Used in {p.count} assignments
                    </p>
                    <Badge>
                      {scope === "show"
                        ? "Show default"
                        : "Inherited from show"}
                    </Badge>
                  </div>
                </button>
              ))}
            </div>
          </>
        );
      case "preset-editor":
        return <>
          {header("Palettes & phasers", "Build static attribute palettes or duplicate a baseline phaser and customize its steps.")}
          {scopeBar}
          <PaletteWorkbench palettes={data.presets} onSave={async (palette, originalName) => {
            await update({ presets: originalName ? data.presets.map(p => p.name === originalName ? palette : p) : [...data.presets, palette],
              script: originalName && originalName !== palette.name ? data.script.map(entry => ({ ...entry, assignments: entry.assignments?.map(a => a.preset === originalName ? {...a, preset: palette.name} : a) })) : data.script });
            setDirty(true);
          }}/>
        </>;
      case "cues":
        return (
          <>
            {header(
              "Give every moment a state.",
              "Cues define the look. Scripts define when it happens.",
              create("cue", "Create cue"),
            )}
            {scopeBar}
            <div className="toolbar">
              <SearchBox
                value={query}
                onChange={setQuery}
                placeholder="Find a cue…"
              />
              <Badge>6 show states</Badge>
            </div>
            {cueTable(matching(cueRows))}
            <Panel title="A cue is reusable">
              <p className="panel-copy">
                Use the same cue more than once in a script. Venue adaptations
                change its resolved assignments without duplicating the whole
                show.
              </p>
            </Panel>
          </>
        );
      case "cue-editor":
        return (
          <>
            {header(
              "Q02 · Into the blue",
              "A complete moment in the show · Used in Main performance",
              <>
                <Button onClick={() => go("rehearsal")}>
                  <Play size={15} />
                  Preview
                </Button>
                <Button primary onClick={save}>
                  Save cue
                </Button>
              </>,
            )}
            {scopeBar}
            <div className="two-col">
              <CuePaletteAssignments data={data} venue={venue} onChange={script => { update({script}); setDirty(true); }}/>
              <Panel title="Transition & behavior">
                <div className="form-fields">
                  <Field label="Fade in (seconds)">
                    <input
                      type="number"
                      min="0"
                      defaultValue="4"
                      onChange={() => setDirty(true)}
                    />
                  </Field>
                  <Field label="Fade out (seconds)">
                    <input
                      type="number"
                      min="0"
                      defaultValue="3"
                      onChange={() => setDirty(true)}
                    />
                  </Field>
                  <Field label="Curve">
                    <select>
                      <option>Linear</option>
                      <option>Ease in / out</option>
                    </select>
                  </Field>
                  <Field label="Entry condition">
                    <select>
                      <option>Operator GO</option>
                      <option>Script timed follow</option>
                    </select>
                  </Field>
                  <Field label="Operator note">
                    <textarea
                      rows={3}
                      defaultValue="Start on the first sustained synth note."
                      onChange={() => setDirty(true)}
                    />
                  </Field>
                </div>
              </Panel>
            </div>
            <Stage look="#7386ee" />
          </>
        );
      case "scripts":
        return (
          <>
            {header(
              "Give the show its rhythm.",
              "The expected sequence of cues, with room for a live moment.",
              create("script", "Create script"),
            )}
            <div className="two-col">
              {["Main performance", "Soundcheck & focus"].map((n, i) => (
                <Panel
                  key={n}
                  title={n}
                  subtitle={
                    i === 0
                      ? "The complete evening, from doors to encore."
                      : "A repeatable check before the audience arrives."
                  }
                  action={
                    <Badge tone={i === 0 ? "green" : "neutral"}>
                      {i === 0 ? "Primary" : "Utility"}
                    </Badge>
                  }
                >
                  <div className="script-preview">
                    {cueRows.slice(0, i === 0 ? 6 : 3).map((c, j) => (
                      <div key={c.id}>
                        <span>{String(j + 1).padStart(2, "0")}</span>
                        <i style={{ background: c.color }} />
                        <strong>{c.name}</strong>
                        <small>Manual GO</small>
                      </div>
                    ))}
                  </div>
                  <div className="panel-bottom">
                    <span>Revision 04 · Draft</span>
                    {editLink("Open script", "script-editor")}
                  </div>
                </Panel>
              ))}
            </div>
          </>
        );
      case "script-editor":
        return (
          <>
            {header(
              "Main performance",
              "Script · Draft revision 04 · Each row references a cue, including repeats.",
              <>
                <Button onClick={() => setModal({ kind: "script-entry" })}>
                  <Plus size={15} />
                  Add cue
                </Button>
                {action("Rehearse", "rehearsal", Play)}
              </>,
            )}
            {scopeBar}
            <Panel
              title="Running order"
              subtitle="Numbered cue slots · Drag to reorder the draft. Changes persist in this browser."
            >
              <ScriptSlots
                entries={data.script}
                onChange={(transform) =>
                  setData((current) => ({
                    ...current,
                    script: transform(current.script),
                  }))
                }
              />
            </Panel>
            <div className="callout">
              <ListMusic size={20} />
              <p>
                Reordering a script never changes the cue definition. A venue
                may override the sequence; the show’s primary script remains the
                default.
              </p>
            </div>
          </>
        );
      case "rehearsal":
      case "live":
        return (
          <LiveConsole
            data={data}
            venue={venue}
            showName={context?.id || urlParams().get("show") || data.showName}
            connected={connected}
            popout={urlParams().get("popout") === "1"}
            rehearsal={route === "rehearsal"}
            onEdit={(id) => {
              if (urlParams().get("popout") !== "1") {
                go(id);
                return;
              }
              const target = new URL(location.href);
              target.searchParams.delete("popout");
              target.searchParams.set("screen", id);
              const editor = window.open(target, "vv-production-editor");
              if (!editor)
                notify(
                  "Allow popups to open the editor; this console remains active.",
                );
            }}
            update={update}
          />
        );
      case "outputs":
        return (
          <>
            {header(
              "Connect the room.",
              "A paired local bridge handles venue networking and physical output.",
              <Button primary onClick={() => setModal({ kind: "bridge" })}>
                <Plus size={16} />
                Pair bridge
              </Button>,
            )}
            <div className="two-col">
              <Panel
                title="Glasshouse · FOH bridge"
                subtitle="Simulated local agent · version 0.1"
                action={
                  <Badge tone={connected ? "green" : "red"}>
                    {connected ? "Demo connected" : "Disconnected"}
                  </Badge>
                }
              >
                <dl>
                  <dt>Network interface</dt>
                  <dd>Ethernet · 192.168.10.20</dd>
                  <dt>Transport</dt>
                  <dd>Art-Net · unicast</dd>
                  <dt>Output ownership</dt>
                  <dd>Alex Morgan · exclusive session</dd>
                  <dt>Cloud synchronization</dt>
                  <dd>Draft synced · sample state</dd>
                </dl>
                <Button
                  onClick={() => {
                    setConnected(!connected);
                    setArmed(false);
                    notify(
                      connected
                        ? "Simulated disconnect. Output controls disarmed."
                        : "Demo bridge reconnected. Re-arm explicitly.",
                    );
                  }}
                >
                  {connected ? <WifiOff size={15} /> : <Network size={15} />}{" "}
                  {connected ? "Simulate disconnect" : "Reconnect demo bridge"}
                </Button>
              </Panel>
              <Panel title="Planning travels. Output stays local.">
                <div className="network-flow">
                  <Monitor />
                  <ArrowRight />
                  <Network />
                  <ArrowRight />
                  <Lightbulb />
                </div>
                <p className="panel-copy">
                  The browser edits the show. A bridge on the venue network
                  evaluates the pinned show revision and sends output to your
                  node.
                </p>
                {editLink("Review recovery flow", "recovery")}
              </Panel>
            </div>
            <Panel title="Universe routing">
              <Table
                headers={[
                  "Logical universe",
                  "Protocol",
                  "Wire address",
                  "Destination",
                  "Output",
                ]}
                rows={[
                  [
                    <strong>Universe 1</strong>,
                    "Art-Net",
                    "Net 0 / Sub-net 0 / Universe 0",
                    "192.168.10.50",
                    <Badge>Simulation only</Badge>,
                  ],
                ]}
              />
            </Panel>
          </>
        );
      case "universe":
        return (
          <>
            {header(
              "See what leaves the engine.",
              "Logical universe 1 · 512 slots · Synthetic preview values",
              <Badge tone="amber">SIMULATED · NOT TELEMETRY</Badge>,
            )}
            <div className="toolbar">
              <Badge>Art-Net address 0:0:0</Badge>
              <Badge>
                {blackout
                  ? "Blackout · all intensity output suppressed"
                  : "Snapshot · cue preview"}
              </Badge>
            </div>
            <div className="universe-grid">
              {Array.from({ length: 512 }, (_, i) => {
                const value = blackout
                  ? 0
                  : i < 96
                    ? [191, 78, 93, 229, 0, 0, 0, 0][i % 8]
                    : 0;
                return (
                  <button
                    key={i}
                    className={value ? "lit" : ""}
                    aria-label={`Slot ${i + 1}: ${value}`}
                    onClick={() =>
                      notify(
                        `Slot ${i + 1} · value ${value} / 255 · synthetic data`,
                      )
                    }
                  >
                    <small>{String(i + 1).padStart(3, "0")}</small>
                    <strong>{value}</strong>
                  </button>
                );
              })}
            </div>
          </>
        );
      case "recovery":
        return (
          <>
            {header(
              "Get back in sync.",
              "Example failure state · Playback must not resume from a stale browser view.",
            )}
            <div className="callout warning">
              <WifiOff size={24} />
              <div>
                <strong>Bridge heartbeat lost · example incident</strong>
                <p>
                  The console’s last known cue is Q02. Actual output is unknown
                  until the bridge reports its current session.
                </p>
              </div>
            </div>
            <div className="two-col">
              <Panel title="Last known state">
                <dl>
                  <dt>Session</dt>
                  <dd>Glasshouse / Main performance</dd>
                  <dt>Last confirmed cue</dt>
                  <dd>Q02 · Into the blue</dd>
                  <dt>Run revision</dt>
                  <dd>Show 04 / Venue 03</dd>
                  <dt>Last heartbeat</dt>
                  <dd>14 seconds ago · demo timestamp</dd>
                  <dt>Local failure policy</dt>
                  <dd>Hold configured output; policy requires validation</dd>
                </dl>
              </Panel>
              <Panel title="Recover deliberately">
                <ol className="recovery-steps">
                  <li>Reconnect to the paired bridge.</li>
                  <li>Fetch active revision, cue, and output ownership.</li>
                  <li>Compare against the browser’s last confirmed state.</li>
                  <li>Confirm control, then explicitly re-arm.</li>
                </ol>
                <Button
                  primary
                  onClick={() => {
                    setConnected(true);
                    setArmed(false);
                    notify(
                      "Demo reconciled. Current output is disarmed; explicitly arm to continue.",
                    );
                    go("live");
                  }}
                >
                  Simulate reconciled reconnect <ArrowRight size={16} />
                </Button>
              </Panel>
            </div>
          </>
        );
      default:
        return (
          <Empty
            title="Choose a programming screen"
            action={
              <Button onClick={() => go("programming")}>Programming</Button>
            }
          />
        );
    }
  }

  function dialogContent() {
    const kind = modal.kind;
    if (kind === "unsaved")
      return (
        <>
          <p>
            You have edits in this screen. Save the local demo values before
            continuing, or stay here.
          </p>
          <div className="form-footer">
            <Button onClick={() => setModal(null)}>Keep editing</Button>
            <Button
              primary
              onClick={() => {
                setDirty(false);
                setRoute(modal.target);
                setModal(null);
                setScenario("ready");
                setQuery("");
              }}
            >
              Save locally & continue
            </Button>
          </div>
        </>
      );
    if (kind === "reset-all")
      return (
        <>
          <p>
            Remove the demo intensity override for {venue}? It will inherit the
            current show value of {data.intensity}%.
          </p>
          <p className="panel-note">
            The illustrated drawing change is not editable in this prototype.
          </p>
          <div className="form-footer">
            <Button onClick={() => setModal(null)}>Cancel</Button>
            <Button
              danger
              onClick={() => {
                setVenueOverride(undefined);
                setModal(null);
                notify("Demo intensity override reset.");
              }}
            >
              Reset intensity override
            </Button>
          </div>
        </>
      );
    if (kind === "script-entry")
      return (
        <form
          onSubmit={(e) => {
            e.preventDefault();
            const id = new FormData(e.currentTarget).get("cue");
            update({
              script: [
                ...data.script,
                {
                  ...cueRows.find((c) => c.id === id),
                  entryId: crypto.randomUUID(),
                },
              ],
            });
            setModal(null);
          }}
        >
          <Field label="Cue reference">
            <select name="cue">
              {cueRows.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.id} · {c.name}
                </option>
              ))}
            </select>
          </Field>
          <p>You can reuse an existing cue without copying its definition.</p>
          <FormFooter onCancel={() => setModal(null)} label="Add to script" />
        </form>
      );
    if (
      [
        "template",
        "duplicate-template",
        "preset",
        "invite",
        "equipment",
        "profile",
        "cue",
        "script",
        "password",
        "bridge",
      ].includes(kind)
    )
      return (
        <form
          onSubmit={(e) => {
            e.preventDefault();
            const name = new FormData(e.currentTarget).get("name").trim();
            if (!name) return;
            if (kind.includes("template"))
              update({ templates: [...data.templates, name] });
            else if (kind === "preset")
              update({
                presets: [
                  ...data.presets,
                  {
                    name,
                    type: "Color",
                    color: "#b7cc98",
                    intensity: 75,
                    count: 0,
                  },
                ],
              });
            else if (kind === "invite")
              update({ members: [...data.members, name] });
            else if (kind === "equipment")
              update({
                fixtures: [
                  ...data.fixtures,
                  {
                    id: `FX-${String(data.fixtures.length + 1).padStart(3, "0")}`,
                    name,
                    model: "VV RGBW Wash",
                    role: "Upstage wash",
                    mode: "8 channel",
                    address: 97 + (data.fixtures.length - 8) * 8,
                    universe: 1,
                    footprint: 8,
                  },
                ],
              });
            setModal(null);
            notify(
              ["profile", "cue", "script", "password", "bridge"].includes(kind)
                ? "Flow preview complete. This service is specified but not implemented."
                : "Added locally for design review; no external service was contacted.",
            );
          }}
        >
          <Field
            label={
              kind === "password"
                ? "Account email"
                : kind === "invite"
                  ? "Teammate email"
                  : kind === "bridge"
                    ? "Pairing code"
                    : "Name"
            }
          >
            <input
              required
              name="name"
              type={["password", "invite"].includes(kind) ? "email" : "text"}
              autoFocus
              placeholder={
                kind === "bridge"
                  ? "VV-482-019"
                  : kind === "invite"
                    ? "teammate@production.co"
                    : "Enter a name"
              }
            />
          </Field>
          {kind === "invite" && (
            <Field label="Role">
              <select>
                <option>Editor</option>
                <option>Operator</option>
                <option>Viewer</option>
              </select>
            </Field>
          )}
          <p className="panel-note">
            Prototype flow. No emails, credentials, or hardware commands are
            sent.
          </p>
          <FormFooter
            onCancel={() => setModal(null)}
            label={kind === "password" ? "Preview recovery" : "Continue"}
          />
        </form>
      );
    return (
      <>
        <div className="callout">
          <Shield size={20} />
          <p>
            {kind === "revision"
              ? "Revision 04 adds two side fixtures and updates the stage width. Review conflicts against venue-specific changes before accepting."
              : kind === "restore"
                ? "Restoring revision 03 would create a new draft revision. The current published run would remain unchanged."
                : kind === "archive"
                  ? "Archiving would retain show history and prevent new runs. Active run ownership must be released first."
                  : "Billing management would open a secure provider portal. No pricing or billing service is configured."}
          </p>
        </div>
        <p>
          This review state is represented in the mockup. The corresponding
          backend operation is not implemented.
        </p>
        <div className="form-footer">
          <Button onClick={() => setModal(null)}>Close review</Button>
        </div>
      </>
    );
  }

  return (
    <div className="programming-preview">
      {renderScreen()}
      {toast && <p role="status">{toast}</p>}
      {modal && (
        <Dialog
          title={modal.kind.replaceAll("-", " ")}
          onClose={() => setModal(null)}
        >
          {dialogContent()}
        </Dialog>
      )}
    </div>
  );
}
createRoot(document.getElementById("root")).render(
  /^\/upload\/?$/.test(location.pathname) ? (
    <StandaloneMovieUpload />
  ) : (
    <Workspace ProgrammingPreview={App} />
  ),
);
