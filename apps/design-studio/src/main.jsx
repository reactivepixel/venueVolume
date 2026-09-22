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
import LiveConsole from "./LiveConsole";
import ScriptSlots from "./ScriptSlots";
import { useSharedState } from "./shared-state";
import { createRun, makeSnapshot } from "./live-model";

const initial = {
  showName: "Afterglow · Fall tour",
  shows: ["Afterglow · Fall tour", "Common ground", "The midnight sessions"],
  venues: ["The Glasshouse", "Mercury Hall", "Northside Theater"],
  templates: ["Touring rig", "Intimate room", "Festival stage"],
  presets: presetRows,
  fixtures: fixtureRows,
  script: cueRows.map((c, i) => ({ ...c, entryId: `entry-${i}` })),
  intensity: 75,
  venueOverrides: { "The Glasshouse": 60 },
  members: ["Alex Morgan", "Jamie Park", "Sam Rivera"],
  uploads: [],
};
function load() {
  try {
    return {
      ...initial,
      ...JSON.parse(localStorage.getItem("vv-design-v1") || "{}"),
    };
  } catch {
    return initial;
  }
}
const nav = [
  ["overview", "Overview", Grid2X2],
  ["templates", "Configurations", Layers],
  ["inventory", "Inventory", Box],
  ["venues", "Venues", MapPin],
  ["presets", "Presets", SlidersHorizontal],
  ["cues", "Cues", Zap],
  ["scripts", "Scripts", ListMusic],
  ["assets", "Files & drawings", Folder],
];
const urlParams = () => new URLSearchParams(location.search);
function App() {
  const [data, setData] = useSharedState("vv-design-v1", load()),
    [route, setRoute] = useState(urlParams().get("screen") || "overview"),
    [mode, setMode] = useState(urlParams().get("mode") || "hifi"),
    [scenario, setScenario] = useState(urlParams().get("state") || "ready");
  const [gallery, setGallery] = useState(false),
    [query, setQuery] = useState(""),
    [modal, setModal] = useState(null),
    [toast, setToast] = useState(""),
    [scope, setScope] = useState("show"),
    [venue, setVenue] = useState(urlParams().get("venue") || "The Glasshouse"),
    [selected, setSelected] = useState(0),
    [connected, setConnected] = useSharedState("vv-demo-connected", true),
    [dirty, setDirty] = useState(false);
  const screen = screens.find((s) => s.id === route) || screens[4];
  const [liveRun, setLiveRun] = useSharedState(
    `vv-live-v2:${encodeURIComponent(urlParams().get("show") || data.showName)}:${encodeURIComponent(venue)}:live`,
    createRun(makeSnapshot(data, venue)),
  );
  const blackout = liveRun.blackout;
  const setArmed = (value) =>
    setLiveRun((previous) => ({ ...previous, armed: value }));
  useEffect(() => {
    const p = new URLSearchParams(location.search);
    p.set("screen", route);
    p.set("mode", mode);
    p.set("state", scenario);
    history.replaceState({}, "", `?${p}`);
    document.title = `${screen.title} · Venue Volume`;
  }, [route, mode, scenario]);
  useEffect(() => {
    if (!toast) return;
    const t = setTimeout(() => setToast(""), 4000);
    return () => clearTimeout(t);
  }, [toast]);
  function go(id) {
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
    setData((d) => ({ ...d, ...values }));
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
      headers={["Cue", "State", "Preset", "Fade", "Scope", ""]}
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
      case "sign-in":
        return (
          <div className="auth-grid">
            <div className="auth-art">
              <div className="eyebrow">THE ROOM IS YOUR INSTRUMENT.</div>
              <h1>
                One show.
                <br />
                Every stage.
              </h1>
              <p>
                Build your world once.
                <br />
                Bring it to life, wherever you play.
              </p>
              <Stage look="#afca85" />
              <span>VENUE VOLUME / PRODUCTION CONTROL</span>
            </div>
            <form
              className="auth-form"
              onSubmit={(e) => {
                e.preventDefault();
                go("shows");
                notify("Demo workspace opened; no credentials were sent.");
              }}
            >
              <Badge tone="green">INTERACTIVE PROTOTYPE</Badge>
              <h1>Welcome back.</h1>
              <p>Your next great show starts here.</p>
              <Field label="Work email">
                <input type="email" placeholder="you@production.co" required />
              </Field>
              <Field label="Password">
                <input
                  type="password"
                  minLength={8}
                  required
                  placeholder="At least 8 characters"
                />
              </Field>
              <button className="button primary" type="submit">
                Open demo workspace <ArrowRight size={16} />
              </button>
              <Button onClick={() => setModal({ kind: "password" })}>
                Forgot password?
              </Button>
              <div className="divider" />
              <p>Starting something new?</p>
              {editLink("Create a workspace", "workspace")}
              <small>No authentication is implemented in this mockup.</small>
            </form>
          </div>
        );
      case "workspace":
        return (
          <>
            {header(
              "Make room for your team.",
              "A shared workspace for your people, productions, and places.",
            )}
            <form
              className="form-card narrow"
              onSubmit={(e) => {
                e.preventDefault();
                go("shows");
                notify("Demo workspace created.");
              }}
            >
              <div className="steps">
                <Badge tone="green">01 Workspace</Badge>
                <span>02 First show</span>
                <span>03 Invite team</span>
              </div>
              <Field label="Workspace name">
                <input required defaultValue="Afterglow Productions" />
              </Field>
              <Field label="Workspace URL">
                <div className="input-affix">
                  venuevolume.app / <input required defaultValue="afterglow" />
                </div>
              </Field>
              <Field label="Your role">
                <select>
                  <option>Lighting designer / programmer</option>
                  <option>Production manager</option>
                  <option>Venue operator</option>
                </select>
              </Field>
              <Field label="Primary timezone">
                <select>
                  <option>America/New_York</option>
                  <option>Europe/London</option>
                  <option>UTC</option>
                </select>
              </Field>
              <FormFooter
                onCancel={() => go("sign-in")}
                label="Create demo workspace"
              />
            </form>
          </>
        );
      case "shows":
        return (
          <>
            {header(
              "Your productions.",
              "A home for every show, from the first idea to the final encore.",
              action("Create show", "new-show"),
            )}
            <div className="toolbar">
              <SearchBox
                value={query}
                onChange={setQuery}
                placeholder="Find a show…"
              />
              <Badge>{data.shows.length} active shows</Badge>
            </div>
            <div className="show-grid">
              {matching(data.shows).map((name, i) => (
                <button
                  className="show-card"
                  key={name}
                  onClick={() => {
                    update({ showName: name });
                    go("overview");
                  }}
                >
                  <div className={`show-art art-${i % 3}`}>
                    <div className="beam b1" />
                    <div className="beam b2" />
                    <div className="beam b3" />
                    <span>{String(i + 1).padStart(2, "0")} / PRODUCTION</span>
                    <strong>
                      {i === 0
                        ? "AFTER\nGLOW"
                        : i === 1
                          ? "COMMON\nGROUND"
                          : "MIDNIGHT\nSESSIONS"}
                    </strong>
                  </div>
                  <div className="show-card-body">
                    <h2>{name}</h2>
                    <p>
                      {i === 0
                        ? "Fall 2026 · Touring production"
                        : "2026 · In development"}
                    </p>
                    <div>
                      <Badge tone={i === 0 ? "green" : "neutral"}>
                        {i === 0 ? "In rehearsal" : "Draft"}
                      </Badge>
                      <span>
                        {i === 0 ? data.venues.length : 1} venues{" "}
                        <ArrowUpRight size={14} />
                      </span>
                    </div>
                  </div>
                </button>
              ))}
            </div>
            {matching(data.shows).length === 0 && (
              <Empty
                title="No matching shows"
                detail="Try another name or create a new show."
              />
            )}
          </>
        );
      case "new-show":
        return (
          <>
            {header(
              "Start with a show.",
              "Your reusable home for rigs, venues, presets, cues, and scripts.",
            )}
            <form
              className="form-card narrow"
              onSubmit={(e) => {
                e.preventDefault();
                const f = new FormData(e.currentTarget);
                const name = f.get("name").trim();
                if (!name) return;
                update({ showName: name, shows: [...data.shows, name] });
                go("overview");
                notify(
                  "Show added to this demo. Sample production content is retained for design review.",
                );
              }}
            >
              <Field label="Show name">
                <input
                  name="name"
                  required
                  placeholder="e.g. Afterglow · Fall tour"
                />
              </Field>
              <Field label="Description">
                <textarea
                  placeholder="Tell your team what you’re making."
                  rows={3}
                />
              </Field>
              <div className="field-grid">
                <Field label="Production type">
                  <select>
                    <option>Touring production</option>
                    <option>Single venue</option>
                    <option>Festival</option>
                  </select>
                </Field>
                <Field label="Opening date">
                  <input type="date" defaultValue="2026-10-12" />
                </Field>
              </div>
              <div className="callout">
                <Layers size={20} />
                <div>
                  <strong>A show travels with you.</strong>
                  <p>
                    Start with show defaults. Add configuration templates, then
                    adapt them for each venue.
                  </p>
                </div>
              </div>
              <FormFooter label="Create show" onCancel={() => go("shows")} />
            </form>
          </>
        );
      case "overview":
        return (
          <>
            {header(
              data.showName,
              "Design the show once. Make every room your own.",
              <>
                <Button onClick={() => go("settings")}>
                  <Settings size={15} />
                  Show settings
                </Button>
                {action("Open rehearsal", "rehearsal", Play)}
              </>,
            )}
            <div className="overview-banner">
              <div>
                <Badge tone="green">FALL 2026 / TOURING PRODUCTION</Badge>
                <h2>
                  A different room.
                  <br />
                  The same feeling.
                </h2>
                <p>Your next stop is {venue}. Let’s make it yours.</p>
                <Button onClick={() => go("venue-detail")}>
                  Prepare this venue <ArrowUpRight size={16} />
                </Button>
              </div>
              <div className="banner-art">
                <span>VV / 026</span>
                <div className="orb" />
                <span>AFTERGLOW</span>
              </div>
            </div>
            <div className="metrics">
              <Metric
                label="VENUES"
                value={String(data.venues.length).padStart(2, "0")}
                detail="Next · The Glasshouse"
              />
              <Metric
                label="CONFIGURATIONS"
                value={String(data.templates.length).padStart(2, "0")}
                detail="Reusable production rigs"
              />
              <Metric
                label="LIGHTING FIXTURES"
                value="08"
                detail="Across 3 fixture profiles"
              />
              <Metric
                label="CUES IN MAIN SCRIPT"
                value={String(data.script.length).padStart(2, "0")}
                detail="Draft revision 04"
              />
            </div>
            <div className="two-col">
              <Panel
                title="The next room"
                subtitle="The Glasshouse · Brooklyn, NY"
                action={<Badge tone="amber">2 overrides</Badge>}
              >
                <Stage />
                <div className="panel-bottom">
                  <span>Touring rig · revision 03</span>
                  {editLink("Open venue", "venue-detail")}
                </div>
              </Panel>
              <div className="stack">
                <Panel title="Pick up where you left off">
                  <RowLink
                    icon={ListMusic}
                    title="Main performance"
                    detail="Script · Updated 18 minutes ago"
                    onClick={() => go("script-editor")}
                  />
                  <RowLink
                    icon={SlidersHorizontal}
                    title="Midnight blue"
                    detail="Preset · Show default"
                    onClick={() => go("preset-editor")}
                  />
                  <RowLink
                    icon={Layers}
                    title="Touring rig"
                    detail="Configuration · Revision 03"
                    onClick={() => go("template-detail")}
                  />
                </Panel>
                <Panel
                  title="Ready for the room?"
                  action={editLink("Run checks", "preflight")}
                >
                  <Progress label="Fixture patch" percent={100} />
                  <Progress label="Cue assignments" percent={100} />
                  <Progress label="Venue review" percent={75} />
                  <p className="panel-note">
                    Finish venue review before starting an output session.
                  </p>
                </Panel>
              </div>
            </div>
          </>
        );
      case "templates":
        return (
          <>
            {header(
              "A rig for every kind of room.",
              "Configuration templates bring drawings and equipment together.",
              create("template", "New configuration"),
            )}
            <div className="toolbar">
              <SearchBox
                value={query}
                onChange={setQuery}
                placeholder="Find a configuration…"
              />
              <Badge>SHOW LEVEL</Badge>
            </div>
            <div className="three-col">
              {matching(data.templates).map((t, i) => (
                <Panel
                  key={t}
                  title={t}
                  subtitle={
                    i === 0
                      ? "Your standard touring configuration"
                      : "Alternative production configuration"
                  }
                >
                  <Stage look={["#afca85", "#e3b178", "#a99bd6"][i % 3]} />
                  <div className="template-meta">
                    <span>8 fixtures · 12 equipment items</span>
                    <Badge>rev. 03</Badge>
                  </div>
                  <Button onClick={() => go("template-detail")}>
                    Open configuration <ArrowUpRight size={15} />
                  </Button>
                </Panel>
              ))}
            </div>
          </>
        );
      case "template-detail":
        return (
          <>
            {header(
              "Touring rig",
              "Configuration template · Revision 03 · Used by 2 venues",
              <>
                <Button
                  onClick={() => setModal({ kind: "duplicate-template" })}
                >
                  <Copy size={15} />
                  Duplicate
                </Button>
                {action("Edit drawing", "template-editor", Pencil)}
              </>,
            )}
            {tabs([
              ["Overview", "template-detail"],
              ["Drawing", "template-editor"],
              ["Inventory", "inventory"],
            ])}
            <div className="two-col">
              <Stage large />
              <div className="stack">
                <Panel title="A reusable starting point">
                  <p className="panel-copy">
                    The standard eight-fixture touring rig, with audio, staging,
                    cabling, and a saved technical drawing.
                  </p>
                  <dl>
                    <dt>Drawing</dt>
                    <dd>afterglow-touring-rig.dxf</dd>
                    <dt>Stage footprint</dt>
                    <dd>12 × 8 meters</dd>
                    <dt>Lighting fixtures</dt>
                    <dd>8 instances / 3 profiles</dd>
                    <dt>Total equipment</dt>
                    <dd>12 line items</dd>
                  </dl>
                </Panel>
                <Panel title="Venues using this revision">
                  <RowLink
                    icon={MapPin}
                    title="The Glasshouse"
                    detail="2 local overrides"
                    onClick={() => go("venue-detail")}
                  />
                  <RowLink
                    icon={MapPin}
                    title="Mercury Hall"
                    detail="Uses template defaults"
                    onClick={() => {
                      setVenue("Mercury Hall");
                      go("venue-detail");
                    }}
                  />
                </Panel>
                <div className="callout">
                  <Layers size={19} />
                  <p>
                    Venues pin a template revision. Publishing a new revision
                    starts a review; it does not silently change a venue.
                  </p>
                </div>
              </div>
            </div>
          </>
        );
      case "template-editor":
      case "venue-layout":
        return (
          <>
            {header(
              route === "venue-layout"
                ? `${venue} · Drawing`
                : "Touring rig · Drawing",
              "A shared spatial reference for equipment, fixture roles, and patching.",
              <>
                <Button onClick={() => go("assets")}>
                  <Upload size={15} />
                  Drawings
                </Button>
                <Button primary onClick={save}>
                  <Check size={15} />
                  {dirty ? "Save changes" : "Save revision"}
                </Button>
              </>,
            )}
            {route === "venue-layout" && scopeBar}
            <div className="editor-grid">
              <aside className="panel compact">
                <h2>Layers</h2>
                {[
                  "Venue boundary",
                  "Truss & rigging",
                  "Lighting fixtures",
                  "Audio & staging",
                  "Dimensions",
                ].map((n, i) => (
                  <label className="check-row" key={n}>
                    <input type="checkbox" defaultChecked />
                    {n}
                    <span>{i + 1}</span>
                  </label>
                ))}
                <div className="divider" />
                <h2>Placed equipment</h2>
                {data.fixtures.map((f, i) => (
                  <button
                    className={`fixture-row ${selected === i ? "selected" : ""}`}
                    key={f.id}
                    onClick={() => setSelected(i)}
                  >
                    <Lightbulb size={14} />
                    {f.name}
                  </button>
                ))}
              </aside>
              <Stage
                large
                selected={selected}
                onSelect={setSelected}
                wire={mode === "wire"}
              />
              <aside className="panel compact">
                <Badge tone="green">SELECTED FIXTURE</Badge>
                <h2>{data.fixtures[selected].name}</h2>
                <p>{data.fixtures[selected].id}</p>
                <Field label="Fixture role">
                  <select onChange={() => setDirty(true)}>
                    <option>Upstage wash</option>
                    <option>Front key</option>
                    <option>Side beams</option>
                  </select>
                </Field>
                <div className="field-grid">
                  <Field label="X position (m)">
                    <input
                      type="number"
                      defaultValue="2.4"
                      onChange={() => setDirty(true)}
                    />
                  </Field>
                  <Field label="Y position (m)">
                    <input
                      type="number"
                      defaultValue="1.2"
                      onChange={() => setDirty(true)}
                    />
                  </Field>
                </div>
                <Field label="Rotation (degrees)">
                  <input
                    type="number"
                    defaultValue="0"
                    onChange={() => setDirty(true)}
                  />
                </Field>
                <Badge>
                  {route === "venue-layout"
                    ? "Inherited placement"
                    : "Template placement"}
                </Badge>
                <div className="divider" />
                {editLink("View fixture details", "equipment")}
                <p className="panel-note">
                  Layout mockup. Geometry editing and CAD conversion are
                  specified in F04.
                </p>
              </aside>
            </div>
          </>
        );
      case "inventory":
        return (
          <>
            {header(
              "Everything that makes the show.",
              "Fixtures, truss, audio, staging, and the small things that hold it all together.",
              create("equipment", "Add equipment"),
            )}
            {scopeBar}
            <div className="toolbar">
              <SearchBox
                value={query}
                onChange={setQuery}
                placeholder="Find equipment…"
              />
              <Badge>12 line items · 8 patched fixtures</Badge>
            </div>
            <Panel title="Production inventory">
              <Table
                headers={[
                  "Equipment",
                  "Category",
                  "Quantity",
                  "Source",
                  "Status",
                  "",
                ]}
                rows={[
                  ...matching(data.fixtures).map((f) => [
                    <span>
                      <strong>{f.name}</strong>
                      <small>
                        {f.model} · {f.id}
                      </small>
                    </span>,
                    "Lighting",
                    "1",
                    <Badge>Template</Badge>,
                    <Badge tone="green">Patched</Badge>,
                    editLink("Inspect", "equipment"),
                  ]),
                  ...(!query
                    ? [
                        [
                          "Powered loudspeaker",
                          "Audio",
                          "2",
                          <Badge>Template</Badge>,
                          "No DMX",
                          editLink("Inspect", "equipment"),
                        ],
                        [
                          "Box truss · 3 m",
                          "Rigging",
                          "4",
                          <Badge>Template</Badge>,
                          "No DMX",
                          editLink("Inspect", "equipment"),
                        ],
                        [
                          "Drum riser · 2 × 2 m",
                          "Staging",
                          "1",
                          <Badge>Template</Badge>,
                          "No DMX",
                          editLink("Inspect", "equipment"),
                        ],
                        [
                          "DMX cable · 10 m",
                          "Cabling",
                          "12",
                          <Badge>Template</Badge>,
                          "No DMX",
                          editLink("Inspect", "equipment"),
                        ],
                      ]
                    : []),
                ]}
              />
            </Panel>
          </>
        );
      case "equipment":
        return (
          <>
            {header(
              "Upstage wash 01",
              "Inventory item · FX-001",
              <Button primary onClick={save}>
                Save equipment
              </Button>,
            )}
            <div className="two-col">
              <Panel title="Equipment information">
                <div className="form-fields">
                  <Field label="Display name">
                    <input
                      defaultValue="Upstage wash 01"
                      onChange={() => setDirty(true)}
                    />
                  </Field>
                  <Field label="Category">
                    <select onChange={() => setDirty(true)}>
                      <option>Lighting</option>
                      <option>Audio</option>
                      <option>Rigging</option>
                      <option>Staging</option>
                      <option>Cabling</option>
                    </select>
                  </Field>
                  <div className="field-grid">
                    <Field label="Quantity">
                      <input
                        type="number"
                        min="1"
                        defaultValue="1"
                        onChange={() => setDirty(true)}
                      />
                    </Field>
                    <Field label="Ownership">
                      <select>
                        <option>Owned</option>
                        <option>Rental</option>
                        <option>Venue supplied</option>
                      </select>
                    </Field>
                  </div>
                  <Field label="Notes">
                    <textarea
                      defaultValue="Upstage left. Label both power and DMX tails."
                      rows={4}
                    />
                  </Field>
                </div>
              </Panel>
              <div className="stack">
                <Panel title="Control profile">
                  <dl>
                    <dt>Fixture profile</dt>
                    <dd>VV RGBW Wash</dd>
                    <dt>Mode</dt>
                    <dd>8 channel</dd>
                    <dt>Role</dt>
                    <dd>Upstage wash</dd>
                    <dt>Address</dt>
                    <dd>U1 / 001–008</dd>
                  </dl>
                  {editLink("Inspect profile", "fixture")}
                </Panel>
                <Panel title="Used in this production">
                  <RowLink
                    title="Touring rig"
                    detail="Template revision 03"
                    onClick={() => go("template-detail")}
                  />
                  <RowLink
                    title={venue}
                    detail="Inherited equipment instance"
                    onClick={() => go("venue-detail")}
                  />
                </Panel>
              </div>
            </div>
          </>
        );
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
      case "venues":
        return (
          <>
            {header(
              "Same show. Different rooms.",
              "Each venue begins with a configuration, then becomes its own.",
              action("Add venue", "new-venue"),
            )}
            <div className="toolbar">
              <SearchBox
                value={query}
                onChange={setQuery}
                placeholder="Find a venue…"
              />
              <Badge>{data.venues.length} stops</Badge>
            </div>
            <div className="three-col">
              {matching(data.venues).map((v, i) => (
                <Panel
                  key={v}
                  title={v}
                  subtitle={
                    [
                      "Brooklyn, NY · Oct 12",
                      "Philadelphia, PA · Oct 15",
                      "Boston, MA · Oct 18",
                    ][i % 3]
                  }
                >
                  <div className={`venue-illustration venue-${i % 3}`}>
                    <Building2 size={85} strokeWidth={0.8} />
                    <span>{String(i + 1).padStart(2, "0")} / TOUR STOP</span>
                  </div>
                  <div className="template-meta">
                    <span>
                      {i === 2 ? "Intimate room" : "Touring rig"} · rev. 03
                    </span>
                    <Badge tone={i === 0 ? "amber" : "green"}>
                      {i === 0 ? "2 overrides" : "Inherited"}
                    </Badge>
                  </div>
                  <Button
                    onClick={() => {
                      setVenue(v);
                      go("venue-detail");
                    }}
                  >
                    Open venue <ArrowUpRight size={15} />
                  </Button>
                </Panel>
              ))}
            </div>
          </>
        );
      case "new-venue":
        return (
          <>
            {header(
              "Give your show a new home.",
              "Choose a starting configuration. Keep all changes local to this venue.",
            )}
            <form
              className="form-card narrow"
              onSubmit={(e) => {
                e.preventDefault();
                const f = new FormData(e.currentTarget),
                  name = f.get("name").trim();
                if (!name) return;
                update({ venues: [...data.venues, name] });
                setVenue(name);
                go("venue-detail");
              }}
            >
              <Field label="Venue name">
                <input name="name" placeholder="e.g. The Glasshouse" required />
              </Field>
              <div className="field-grid">
                <Field label="City">
                  <input placeholder="Brooklyn, NY" />
                </Field>
                <Field label="Performance date">
                  <input type="date" defaultValue="2026-10-12" />
                </Field>
              </div>
              <Field label="Starting configuration">
                <select>
                  {data.templates.map((t) => (
                    <option key={t}>{t} · revision 03</option>
                  ))}
                </select>
              </Field>
              <div className="callout">
                <Layers size={20} />
                <p>
                  The drawing and inventory start from this revision. Presets,
                  cues, and scripts resolve from the show unless you add an
                  override.
                </p>
              </div>
              <FormFooter label="Create venue" onCancel={() => go("venues")} />
            </form>
          </>
        );
      case "venue-detail":
        return (
          <>
            {header(
              venue,
              "Brooklyn, NY · October 12, 2026 · Venue configuration",
              <>
                <Button onClick={() => go("overrides")}>
                  <Layers size={15} />
                  Compare overrides
                </Button>
                {action("Prepare to run", "preflight", Play)}
              </>,
            )}
            {tabs([
              ["Overview", "venue-detail"],
              ["Drawing", "venue-layout"],
              ["Patch", "patch"],
              ["Overrides", "overrides"],
            ])}
            <div className="metrics">
              <Metric
                label="CONFIGURATION"
                value="Touring rig"
                detail="Pinned to revision 03"
              />
              <Metric
                label="LOCAL CHANGES"
                value="02"
                detail="Drawing + preset intensity"
              />
              <Metric label="FIXTURES" value="08" detail="All roles mapped" />
              <Metric
                label="OUTPUT MODE"
                value="Preview"
                detail="Hardware is not connected"
              />
            </div>
            <div className="two-col">
              <Stage large />
              <div className="stack">
                <Panel title="Venue adaptations">
                  <RowLink
                    icon={MapPin}
                    title="Stage depth · 7 meters"
                    detail="Template default: 8 meters"
                    onClick={() => go("venue-layout")}
                    end={<Badge tone="amber">Override</Badge>}
                  />
                  <RowLink
                    icon={SlidersHorizontal}
                    title="Midnight blue · intensity"
                    detail="Show default: 75% → venue: 60%"
                    onClick={() => {
                      setScope("venue");
                      go("preset-editor");
                    }}
                    end={<Badge tone="amber">Override</Badge>}
                  />
                </Panel>
                <Panel title="Preparation">
                  <RowLink
                    icon={Network}
                    title="Patch & universe routing"
                    detail="8 fixtures · Universe 1"
                    onClick={() => go("patch")}
                  />
                  <RowLink
                    icon={ListMusic}
                    title="Main performance"
                    detail="6 cues · 1 venue adaptation"
                    onClick={() => go("script-editor")}
                  />
                  <RowLink
                    icon={ClipboardCheck}
                    title="Preflight check"
                    detail="Verify this venue’s resolved configuration"
                    onClick={() => go("preflight")}
                  />
                </Panel>
              </div>
            </div>
          </>
        );
      case "patch":
        return (
          <>
            {header(
              "Every fixture. The right address.",
              "Venue patch · Logical universe numbers are separate from Art-Net addresses.",
              <Button primary onClick={save}>
                <Check size={15} />
                Save patch
              </Button>,
            )}
            {tabs([
              ["Overview", "venue-detail"],
              ["Drawing", "venue-layout"],
              ["Patch", "patch"],
              ["Overrides", "overrides"],
            ])}
            <div className={`callout ${issues.length ? "warning" : ""}`}>
              {issues.length ? (
                <>
                  <Shield size={20} />
                  <div role="alert">
                    {issues.map((i) => (
                      <p key={i}>{i}</p>
                    ))}
                  </div>
                </>
              ) : (
                <>
                  <CheckCircle2 size={20} />
                  <p>
                    No address conflicts. 96 of 512 slots assigned in logical
                    universe 1.
                  </p>
                </>
              )}
            </div>
            <Table
              headers={[
                "Fixture",
                "Role",
                "Mode",
                "Universe",
                "Start address",
                "Footprint",
              ]}
              rows={data.fixtures.map((f, i) => [
                <strong>{f.name}</strong>,
                f.role,
                f.mode,
                <input
                  className="cell-input"
                  aria-label={`${f.id} universe`}
                  type="number"
                  min="1"
                  value={f.universe}
                  onChange={(e) => {
                    update({
                      fixtures: data.fixtures.map((r, j) =>
                        j === i
                          ? { ...r, universe: Number(e.target.value) }
                          : r,
                      ),
                    });
                    setDirty(true);
                  }}
                />,
                <input
                  className="cell-input"
                  aria-label={`${f.id} address`}
                  type="number"
                  min="1"
                  max="512"
                  value={f.address}
                  onChange={(e) => {
                    update({
                      fixtures: data.fixtures.map((r, j) =>
                        j === i ? { ...r, address: Number(e.target.value) } : r,
                      ),
                    });
                    setDirty(true);
                  }}
                />,
                `${f.footprint} channels`,
              ])}
            />
            <Panel title="Universe occupancy">
              <div className="occupancy">
                {Array.from({ length: 128 }, (_, i) => (
                  <span
                    key={i}
                    className={i < 96 ? "occupied" : ""}
                    title={`Slot ${i + 1}`}
                  />
                ))}
              </div>
              <p className="panel-note">
                Slots 1–128 shown.{" "}
                {editLink("Inspect full universe", "universe")}
              </p>
            </Panel>
          </>
        );
      case "overrides":
        return (
          <>
            {header(
              "Every difference, in the open.",
              `${venue} inherits show defaults and Touring rig revision 03.`,
              <Button onClick={() => setModal({ kind: "reset-all" })}>
                <RotateCcw size={15} />
                Reset demo overrides
              </Button>,
            )}
            <div className="inheritance">
              <span>Show defaults</span>
              <ArrowRight size={18} />
              <span>Touring rig · rev. 03</span>
              <ArrowRight size={18} />
              <strong>{venue}</strong>
            </div>
            <Table
              headers={[
                "Setting",
                "Inherited value",
                "Venue value",
                "Source",
                "Action",
              ]}
              rows={[
                [
                  <strong>Midnight blue / intensity</strong>,
                  `${data.intensity}%`,
                  `${venueOverride ?? data.intensity}%`,
                  <Badge
                    tone={venueOverride === undefined ? "neutral" : "amber"}
                  >
                    {venueOverride === undefined
                      ? "Inherited"
                      : "Venue override"}
                  </Badge>,
                  <Button
                    disabled={venueOverride === undefined}
                    onClick={() => {
                      setVenueOverride(undefined);
                      notify("Intensity now inherits the show default.");
                    }}
                  >
                    Reset to show
                  </Button>,
                ],
                [
                  "Stage depth",
                  "8.0 m",
                  "7.0 m",
                  <Badge tone="amber">Example layout override</Badge>,
                  editLink("Review drawing", "venue-layout"),
                ],
              ]}
            />
            <div className="two-col">
              <Panel title="How values resolve">
                <p className="panel-copy">
                  An explicit venue value wins, including zero. Reset removes
                  the override and restores inheritance. A missing override is
                  different from a blackout value of 0.
                </p>
              </Panel>
              <Panel
                title="Upstream revision available"
                action={<Badge tone="amber">Review</Badge>}
              >
                <p className="panel-copy">
                  Touring rig revision 04 adds two side fixtures. Your venue
                  remains on revision 03 until you review and accept the
                  changes.
                </p>
                <Button onClick={() => setModal({ kind: "revision" })}>
                  Review template update <ArrowRight size={15} />
                </Button>
              </Panel>
            </div>
          </>
        );
      case "presets":
        return (
          <>
            {header(
              "Good looks are worth repeating.",
              "Reusable DMX parameter presets for fixture roles, groups, and individual fixtures.",
              create("preset", "Create preset"),
            )}
            {scopeBar}
            <div className="toolbar">
              <SearchBox
                value={query}
                onChange={setQuery}
                placeholder="Find a preset…"
              />
              <Badge>{data.presets.length} presets</Badge>
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
        return (
          <>
            {header(
              "Midnight blue",
              "Preset · Color + intensity · Upstage wash",
              <Button primary onClick={save}>
                <Check size={15} />
                Save preset
              </Button>,
            )}
            {scopeBar}
            <div className="two-col">
              <div className="stack">
                <Stage large look="#7386ee" />
                <Panel title="Target fixture roles">
                  <div className="chip-row">
                    <Badge tone="green">Upstage wash · 4 fixtures</Badge>
                    <Badge>RGBW capability</Badge>
                  </div>
                  <p className="panel-copy">
                    This preset uses semantic color and intensity values. Each
                    compatible fixture profile resolves those values to its own
                    channels.
                  </p>
                </Panel>
              </div>
              <Panel
                title="Parameter editor"
                subtitle="Preview only · no physical output"
              >
                <div className="form-fields">
                  <div className="parameter-heading">
                    <strong>Intensity</strong>
                    <Badge
                      tone={
                        source.source === "Venue override" ? "amber" : "neutral"
                      }
                    >
                      {source.source}
                    </Badge>
                  </div>
                  <div className="big-value">
                    {source.value}
                    <span>%</span>
                  </div>
                  <input
                    aria-label="Preset intensity"
                    type="range"
                    min="0"
                    max="100"
                    value={source.value}
                    onChange={(e) => {
                      scope === "show"
                        ? update({ intensity: Number(e.target.value) })
                        : setVenueOverride(Number(e.target.value));
                      setDirty(true);
                    }}
                  />
                  {scope === "venue" && (
                    <Button
                      onClick={() => {
                        setVenueOverride(undefined);
                        setDirty(true);
                      }}
                    >
                      <RotateCcw size={14} />
                      Reset to show default ({data.intensity}%)
                    </Button>
                  )}
                  <div className="divider" />
                  <Field label="Color">
                    <input
                      type="color"
                      defaultValue="#7386ee"
                      onChange={() => setDirty(true)}
                    />
                  </Field>
                  <div className="color-swatches">
                    {[
                      "#7386ee",
                      "#b481d5",
                      "#e3b178",
                      "#b7cc98",
                      "#e1e5de",
                    ].map((c) => (
                      <span key={c} style={{ background: c }} />
                    ))}
                  </div>
                  <Field label="Fade behavior">
                    <select onChange={() => setDirty(true)}>
                      <option>Use cue transition</option>
                      <option>Snap at cue start</option>
                    </select>
                  </Field>
                  <Field label="Included parameters">
                    <div className="check-row">
                      <input type="checkbox" defaultChecked />
                      Color
                    </div>
                    <div className="check-row">
                      <input type="checkbox" defaultChecked />
                      Intensity
                    </div>
                  </Field>
                  <p className="panel-note">
                    Excluded parameters are not controlled by this preset.
                    Missing capabilities must be reviewed before publishing.
                  </p>
                </div>
              </Panel>
            </div>
          </>
        );
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
              <Panel
                title="Fixture assignments"
                action={<Badge>3 roles</Badge>}
              >
                <Table
                  headers={["Target", "Preset", "Resolved source"]}
                  rows={["Upstage wash", "Front key", "Side beams"].map(
                    (r, i) => [
                      r,
                      <select
                        aria-label={`${r} preset`}
                        onChange={() => setDirty(true)}
                      >
                        {[
                          data.presets[i + 1],
                          ...data.presets.filter((_, j) => j !== i + 1),
                        ].map((p) => (
                          <option key={p.name}>{p.name}</option>
                        ))}
                      </select>,
                      <Badge>
                        {scope === "show" ? "Show default" : "Inherited"}
                      </Badge>,
                    ],
                  )}
                />
                <p className="panel-note">
                  Unassigned parameters: release to defined base state. Tracking
                  behavior is explicit and versioned.
                </p>
              </Panel>
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
                onChange={(transform) => setData((current) => ({ ...current, script: transform(current.script) }))}
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
            showName={urlParams().get("show") || data.showName}
            connected={connected}
            popout={urlParams().get("popout") === "1"}
            rehearsal={route === "rehearsal"}
            onEdit={id=>{
              if(urlParams().get("popout")!=="1"){go(id);return;}
              const target=new URL(location.href);target.searchParams.delete("popout");target.searchParams.set("screen",id);
              const editor=window.open(target,"vv-production-editor");
              if(!editor)notify("Allow popups to open the editor; this console remains active.");
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
      case "preflight":
        return (
          <>
            {header(
              "A calm check before the moment.",
              "Validate the pinned show and venue revisions before a run.",
              <Button
                onClick={() =>
                  notify(
                    "Demo checks refreshed from the current patch and connection state.",
                  )
                }
              >
                <RotateCcw size={15} />
                Run checks
              </Button>,
            )}
            <div className="two-col">
              <Panel title="Readiness checklist">
                {[
                  [
                    "Show revision",
                    "Draft 04 available for this rehearsal",
                    true,
                  ],
                  [
                    "Venue resolution",
                    "Touring rig 03 + explicit venue overrides",
                    true,
                  ],
                  [
                    "Fixture patch",
                    issues.length
                      ? issues.join("; ")
                      : "8 fixtures · no overlapping addresses",
                    !issues.length,
                  ],
                  [
                    "Cue assignments",
                    "All demo roles have a compatible profile",
                    true,
                  ],
                  [
                    "Bridge connection",
                    connected
                      ? "Simulated connection established"
                      : "Reconnect before arming",
                    connected,
                  ],
                  [
                    "Physical output",
                    "This design prototype cannot send DMX",
                    false,
                  ],
                ].map(([title, detail, ok], i) => (
                  <div className="check-item" key={title}>
                    {ok ? <CheckCircle2 size={21} /> : <Shield size={21} />}
                    <span>
                      <strong>{title}</strong>
                      <small>{detail}</small>
                    </span>
                    <Badge tone={ok ? "green" : i === 5 ? "neutral" : "red"}>
                      {ok ? "Passed" : i === 5 ? "Not implemented" : "Blocked"}
                    </Badge>
                  </div>
                ))}
              </Panel>
              <Panel title="Choose the next step">
                <p className="panel-copy">
                  Rehearsal is available with synthetic output. The production
                  implementation must validate a real bridge and publish a
                  pinned revision before live arming.
                </p>
                <Button
                  primary
                  disabled={!!issues.length || !connected}
                  onClick={() => go("rehearsal")}
                >
                  <Play size={16} />
                  Start rehearsal
                </Button>
                <Button disabled>Arm physical output — unavailable</Button>
                <div className="divider" />
                {editLink("Inspect connections", "outputs")}
              </Panel>
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
      case "assets":
        return (
          <>
            {header(
              "The production, on file.",
              "Original CAD files, derived previews, rider documents, and references.",
              <label className="button primary">
                <Upload size={16} />
                Add local file
                <input type="file" className="sr-only" onChange={localFile} />
              </label>,
            )}
            <Table
              headers={["File", "Type", "Revision", "Used by", "State"]}
              rows={[
                [
                  <span className="with-icon">
                    <File size={18} />
                    afterglow-touring-rig.dxf
                  </span>,
                  "CAD original",
                  "03",
                  "Touring rig",
                  <Badge>Example asset</Badge>,
                ],
                [
                  "afterglow-stage-preview.svg",
                  "Derived preview",
                  "03",
                  "3 venues",
                  <Badge tone="green">Example ready</Badge>,
                ],
                [
                  "production-rider.pdf",
                  "Document",
                  "02",
                  "Show",
                  <Badge>Example asset</Badge>,
                ],
                ...data.uploads.map((f) => [
                  f.name,
                  "Local selection",
                  "New",
                  `${f.size.toLocaleString()} bytes`,
                  <Badge tone="amber">Metadata only</Badge>,
                ]),
              ]}
            />
            <div className="callout">
              <FileText size={20} />
              <p>
                Original CAD files are retained alongside browser previews.
                Format support and conversion fidelity need an R&D spike; no CAD
                conversion occurs in this prototype.
              </p>
            </div>
          </>
        );
      case "activity":
        return (
          <>
            {header(
              "A clear record of every change.",
              "Show history, revisions, and who changed what.",
              <Button onClick={exportShow}>
                <Download size={15} />
                Export demo snapshot
              </Button>,
            )}
            <div className="two-col">
              <Panel title="Recent activity">
                <div className="timeline">
                  {[
                    [
                      "18 minutes ago",
                      "Alex Morgan",
                      "Updated Midnight blue intensity",
                      "Preset · Show default",
                    ],
                    [
                      "42 minutes ago",
                      "Jamie Park",
                      "Added a Glasshouse venue override",
                      "Venue · 75% → 60%",
                    ],
                    [
                      "Yesterday",
                      "Alex Morgan",
                      "Published Touring rig revision 03",
                      "Configuration · 8 fixtures",
                    ],
                    [
                      "Sep 16",
                      "Sam Rivera",
                      "Created Main performance",
                      "Script · 6 cue entries",
                    ],
                  ].map(([time, name, event, detail]) => (
                    <div key={event}>
                      <span className="avatar">
                        {name
                          .split(" ")
                          .map((s) => s[0])
                          .join("")}
                      </span>
                      <section>
                        <small>{time} · Sample event</small>
                        <strong>{event}</strong>
                        <p>
                          {name} · {detail}
                        </p>
                      </section>
                    </div>
                  ))}
                </div>
              </Panel>
              <Panel title="Show revisions">
                <RowLink
                  title="Revision 04"
                  detail="Current draft · Local edits"
                  onClick={() => go("overview")}
                  end={<Badge tone="green">Current</Badge>}
                />
                <RowLink
                  title="Revision 03"
                  detail="Published · Sep 18"
                  onClick={() => setModal({ kind: "restore" })}
                />
                <RowLink
                  title="Revision 02"
                  detail="Published · Sep 16"
                  onClick={() => setModal({ kind: "restore" })}
                />
                <p className="panel-note">
                  Restoring creates a new revision. An active run remains pinned
                  to its existing version.
                </p>
              </Panel>
            </div>
          </>
        );
      case "team":
        return (
          <>
            {header(
              "The people behind the show.",
              "Workspace members and production access.",
              create("invite", "Invite teammate"),
            )}
            <Table
              headers={["Member", "Role", "Show access", "Status"]}
              rows={data.members.map((m, i) => [
                <span className="with-icon">
                  <span className="avatar">
                    {m
                      .split(" ")
                      .map((s) => s[0])
                      .join("")
                      .slice(0, 2)}
                  </span>
                  {m}
                </span>,
                ["Owner", "Editor", "Operator"][i % 3],
                i === 2 ? "Assigned shows" : "All shows",
                <Badge tone="green">Demo member</Badge>,
              ])}
            />
            <Panel title="Permission boundaries">
              <Table
                headers={[
                  "Role",
                  "Plan & edit",
                  "Run show",
                  "Manage members",
                  "Billing",
                ]}
                rows={[
                  ["Owner", "Yes", "Yes", "Yes", "Yes"],
                  ["Editor", "Yes", "If granted", "No", "No"],
                  ["Operator", "View published", "If granted", "No", "No"],
                  ["Viewer", "View", "No", "No", "No"],
                ]}
              />
            </Panel>
          </>
        );
      case "settings":
        return (
          <>
            {header(
              "Show settings",
              "Identity, operating defaults, and a portable copy of your work.",
              <Button primary onClick={save}>
                Save changes
              </Button>,
            )}
            <div className="two-col">
              <Panel title="Show information">
                <div className="form-fields">
                  <Field label="Show name">
                    <input
                      value={data.showName}
                      onChange={(e) => {
                        update({ showName: e.target.value });
                        setDirty(true);
                      }}
                    />
                  </Field>
                  <Field label="Description">
                    <textarea
                      rows={3}
                      defaultValue="Fall touring production. An intimate room, a wide-open feeling."
                    />
                  </Field>
                  <Field label="Default script">
                    <select>
                      <option>Main performance</option>
                      <option>Soundcheck & focus</option>
                    </select>
                  </Field>
                  <Field label="Working timezone">
                    <select>
                      <option>America/New_York</option>
                      <option>UTC</option>
                    </select>
                  </Field>
                </div>
              </Panel>
              <div className="stack">
                <Panel title="Portable by design">
                  <p className="panel-copy">
                    Export the demo’s current show data as JSON. Production
                    exports will include versioned asset and profile references.
                  </p>
                  <Button onClick={exportShow}>
                    <Download size={15} />
                    Export show JSON
                  </Button>
                </Panel>
                <Panel title="Archive this production">
                  <p className="panel-copy">
                    Archived shows retain their history. Active output sessions
                    must be stopped before archiving.
                  </p>
                  <Button danger onClick={() => setModal({ kind: "archive" })}>
                    Review archive
                  </Button>
                </Panel>
              </div>
            </div>
          </>
        );
      case "billing":
        return (
          <>
            {header(
              "Room to grow.",
              "Workspace subscription concept · pricing and limits are not yet decided.",
            )}
            <div className="two-col">
              <Panel
                title="Studio plan"
                subtitle="Illustrative plan · not a commercial offer"
                action={<Badge tone="green">Design proposal</Badge>}
              >
                <div className="big-value">
                  TBD<span> / month</span>
                </div>
                <p className="panel-copy">
                  A workspace for teams producing multiple shows and venues.
                  Pricing, included seats, storage, and bridge entitlements
                  require commercial validation.
                </p>
                <Button onClick={() => setModal({ kind: "billing" })}>
                  Review billing flow
                </Button>
              </Panel>
              <Panel title="Workspace usage">
                <dl>
                  <dt>Shows</dt>
                  <dd>{data.shows.length}</dd>
                  <dt>Members</dt>
                  <dd>{data.members.length}</dd>
                  <dt>Venue configurations</dt>
                  <dd>{data.venues.length}</dd>
                  <dt>Included limits</dt>
                  <dd>To be determined</dd>
                </dl>
                <div className="callout">
                  <Shield size={18} />
                  <p>
                    Proposed policy: entitlement changes must not abruptly stop
                    an already authorized active show.
                  </p>
                </div>
              </Panel>
            </div>
          </>
        );
      default:
        return (
          <Empty
            title="Screen not found"
            action={
              <Button onClick={() => go("overview")}>Return to show</Button>
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

  const workflow =
    route === "live"
      ? "live"
      : [
            "venue-detail",
            "venue-layout",
            "patch",
            "overrides",
            "preset-editor",
            "cue-editor",
            "script-editor",
            "rehearsal",
            "outputs",
            "preflight",
            "recovery",
            "universe",
          ].includes(route)
        ? "programming"
        : "preprogramming";
  const detached = urlParams().get("popout") === "1";
  return (
    <div
      data-workflow={workflow}
      className={`app ${mode === "wire" ? "wireframe" : ""} ${detached ? "console-popout" : ""}`}
    >
      <div className="review-bar">
        <span>
          <span className="review-dot" /> VENUE VOLUME <b>/ DESIGN STUDY 01</b>
        </span>
        <div>
          <div className="segmented">
            <button
              className={mode === "wire" ? "active" : ""}
              onClick={() => setMode("wire")}
            >
              01 Wireframes
            </button>
            <button
              className={mode === "hifi" ? "active" : ""}
              onClick={() => setMode("hifi")}
            >
              02 High fidelity
            </button>
          </div>
          <select
            aria-label="Review state"
            value={scenario}
            onChange={(e) => setScenario(e.target.value)}
          >
            <option value="ready">Populated state</option>
            <option value="empty">Empty state</option>
            <option value="loading">Loading state</option>
            <option value="error">Error state</option>
            <option value="read-only">Permission denied</option>
          </select>
          <Button onClick={() => setGallery(!gallery)}>
            <Grid2X2 size={14} />
            {screens.length} screens
          </Button>
        </div>
      </div>
      {gallery && (
        <div className="screen-gallery">
          <div className="gallery-heading">
            <div>
              <h2>The whole production, screen by screen.</h2>
              <p>Choose a screen. Switch fidelity without losing your place.</p>
            </div>
            <Button
              aria-label="Close screen browser"
              onClick={() => setGallery(false)}
            >
              <X size={18} />
            </Button>
          </div>
          {["Workspace", "Show", "Venue", "Program", "Operate", "Manage"].map(
            (section) => (
              <section key={section}>
                <h3>{section}</h3>
                <div>
                  {screens
                    .filter((s) => s.section === section)
                    .map((s) => (
                      <button
                        key={s.id}
                        onClick={() => go(s.id)}
                        className={route === s.id ? "active" : ""}
                      >
                        <span>{s.number}</span>
                        <strong>{s.title}</strong>
                        <small>{s.feature}</small>
                      </button>
                    ))}
                </div>
              </section>
            ),
          )}
        </div>
      )}
      <div className="app-shell">
        <aside className="sidebar" data-region="01 · Navigation">
          <button className="brand" onClick={() => go("shows")}>
            <span className="brand-mark">
              v<span>v</span>
            </span>
            <span>
              venue
              <br />
              <b>volume</b>
            </span>
          </button>
          <button className="workspace-picker" onClick={() => go("shows")}>
            <span className="workspace-avatar">A</span>
            <span>
              Afterglow Productions<small>Company workspace</small>
            </span>
            <ChevronDown size={13} />
          </button>
          <div className="sidebar-label">PRODUCTION</div>
          <button className="show-picker" onClick={() => go("shows")}>
            <span className="tiny-orb" />
            {data.showName}
            <ChevronDown size={13} />
          </button>
          <nav aria-label="Show navigation">
            {nav.map(([id, title, Icon]) => (
              <button
                key={id}
                className={
                  route === id || route.startsWith(id.slice(0, -1) + "-")
                    ? "active"
                    : ""
                }
                onClick={() => go(id)}
              >
                <Icon size={17} />
                {title}
                {id === "venues" && <small>{data.venues.length}</small>}
              </button>
            ))}
          </nav>
          <div className="sidebar-label">IN THE ROOM</div>
          <nav aria-label="Operations">
            <button
              className={route === "live" ? "active" : ""}
              onClick={() => go("live")}
            >
              <Radio size={17} />
              Live console
              <span className="status-dot" />
            </button>
            <button onClick={() => go("outputs")}>
              <Network size={17} />
              Connections
            </button>
            <button onClick={() => go("library")}>
              <Lightbulb size={17} />
              Fixture library
            </button>
          </nav>
          <div className="sidebar-bottom">
            <button onClick={() => go("team")}>
              <Users size={16} />
              Team & access
            </button>
            <button onClick={() => go("activity")}>
              <Activity size={16} />
              Activity & versions
            </button>
            <button onClick={() => go("billing")}>
              <Gauge size={16} />
              Plan & billing
            </button>
            <div className="profile">
              <span className="avatar">AM</span>
              <span>
                Alex Morgan<small>Workspace owner</small>
              </span>
              <Button
                aria-label="Open sign in screen"
                onClick={() => go("sign-in")}
              >
                <MoreHorizontal size={16} />
              </Button>
            </div>
          </div>
        </aside>
        <div className="workspace-main">
          <header className="topbar">
            <div className="breadcrumbs">
              <button onClick={() => go("shows")}>Shows</button>
              <ChevronRight size={13} />
              <button onClick={() => go("overview")}>{data.showName}</button>
              <ChevronRight size={13} />
              <span>{screen.title}</span>
            </div>
            <div className="topbar-right">
              <span className="save-status">
                <span className="status-dot" />
                {dirty ? "Unsaved draft" : "Local demo"}
              </span>
              <span className="avatar small">AM</span>
            </div>
          </header>
          <nav className="workflow-modes" aria-label="Production workflow">
            <button
              className={workflow === "preprogramming" ? "current" : ""}
              data-phase="preprogramming"
              onClick={() => go("overview")}
            >
              <span>01</span>Pre-programming<small>Design the show</small>
            </button>
            <button
              className={workflow === "programming" ? "current" : ""}
              data-phase="programming"
              onClick={() => go("preset-editor")}
            >
              <span>02</span>Programming<small>Adapt this venue</small>
            </button>
            <button
              className={workflow === "live" ? "current" : ""}
              data-phase="live"
              onClick={() => go("live")}
            >
              <span>03</span>Live<small>Operate the room</small>
            </button>
          </nav>
          <main
            key={route}
            className={["live", "rehearsal"].includes(route) ? "live-page" : ""}
          >
            {mode === "wire" && (
              <div className="wire-note">
                <strong>WIREFRAME {screen.number}</strong>
                <span>{screen.purpose}</span>
                <Badge>{screen.feature}</Badge>
              </div>
            )}
            {scenario === "loading" ? (
              <div role="status" className="loading-state">
                <div className="skeleton title" />
                {[1, 2, 3, 4].map((n) => (
                  <div className="skeleton" key={n} />
                ))}
                <p>Loading the show’s pinned revision…</p>
              </div>
            ) : scenario === "error" ? (
              <Empty
                title="We couldn’t load this revision"
                detail="Your local work is preserved. Retry when the connection is available."
                action={
                  <Button primary onClick={() => setScenario("ready")}>
                    Retry
                  </Button>
                }
              />
            ) : scenario === "read-only" ? (
              <Empty
                title="You don’t have edit access"
                detail="Ask the workspace owner to grant the permission required for this screen."
                action={
                  <Button
                    onClick={() => {
                      setScenario("ready");
                      go("team");
                    }}
                  >
                    View team & access
                  </Button>
                }
              />
            ) : scenario === "empty" ? (
              <Empty
                title={`Your ${screen.title.toLowerCase()} starts here`}
                detail={screen.purpose}
                action={
                  <Button primary onClick={() => setScenario("ready")}>
                    Load sample content
                  </Button>
                }
              />
            ) : (
              renderScreen()
            )}
          </main>
          <footer className="workspace-footer">
            <span>
              VENUE VOLUME <span>/</span> MADE FOR THE MOMENT.
            </span>
            <span>
              {screen.number} / {screens.length} ·{" "}
              {mode === "wire" ? "WIREFRAME" : "HIGH FIDELITY"} ·{" "}
              {screen.feature}
            </span>
            <span>Design prototype · no physical output</span>
          </footer>
        </div>
      </div>
      {toast && (
        <div className="toast" role="status">
          <CheckCircle2 size={18} />
          {toast}
        </div>
      )}
      {modal && (
        <Dialog
          title={modal.kind
            .split("-")
            .map((w) => w[0].toUpperCase() + w.slice(1))
            .join(" ")}
          onClose={() => setModal(null)}
        >
          {dialogContent()}
        </Dialog>
      )}
    </div>
  );
}
createRoot(document.getElementById("root")).render(<App />);
