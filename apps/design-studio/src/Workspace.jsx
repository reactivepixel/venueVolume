import React, { useEffect, useState, lazy, Suspense } from "react";
import {
  ArrowRight,
  Box,
  Check,
  Download,
  Layers,
  MapPin,
  Plus,
  Route,
  Upload,
} from "lucide-react";
import {
  Badge,
  Button,
  Dialog,
  Empty,
  Field,
  FormFooter,
  Metric,
  Panel,
  SearchBox,
  Table,
} from "./components";
import {
  IntakeConnection,
  MovieUploadForm,
  VenueMovieDetail,
} from "./VenueMovies";
import { useVenueLibrary, processingLabel } from "./venue-api";
import { useSharedState } from "./shared-state";
import {
  baseChanges,
  emptyWorkspace,
  fixturesFor,
  inventoryIds,
  readiness,
  transition,
  workspaceKey,
} from "./workspace-model";
import "./workspace.css";
import VisionProHandoff from "./VisionProHandoff";

const VenueSceneReview = lazy(() => import("./VenueSceneReview"));

const navigation = [
  ["overview", "Overview"],
  ["venues", "Scanned venues"],
  ["loadouts", "Load Outs"],
  ["inventory", "Fixture inventory"],
  ["tours", "Tours"],
  ["programming", "Programming"],
  ["operations", "Rehearsal & live"],
  ["scene-review", "3D review"],
  ["assets", "Files"],
  ["activity", "Activity"],
  ["team", "Team & access"],
  ["settings", "Workspace settings"],
  ["billing", "Plan & billing"],
];
const uid = () => crypto.randomUUID();
const params = () => new URLSearchParams(location.search);
const aliases = {
  templates: "loadouts",
  "template-detail": "loadouts",
  "template-editor": "loadouts",
  "venue-layout": "loadout",
  "new-venue": "upload",
  shows: "tours",
  "new-show": "tours",
  workspace: "overview",
  "sign-in": "overview",
  equipment: "inventory",
};
const programRoutes = [
  "presets",
  "preset-editor",
  "cues",
  "cue-editor",
  "scripts",
  "script-editor",
];
const operationRoutes = [
  "rehearsal",
  "live",
  "outputs",
  "universe",
  "recovery",
];

function Selection({ units, selected, onChange, locked = [] }) {
  return (
    <div className="unit-selection">
      {units.length ? (
        units.map((unit) => (
          <label key={unit.id}>
            <input
              type="checkbox"
              checked={selected.includes(unit.id)}
              disabled={locked.includes(unit.id)}
              onChange={(e) =>
                onChange(
                  e.target.checked
                    ? [...selected, unit.id]
                    : selected.filter((id) => id !== unit.id),
                )
              }
            />
            <span>
              <strong>{unit.name}</strong>
              <small>
                {unit.model} · {unit.id.slice(0, 8)}
              </small>
            </span>
            {locked.includes(unit.id) && <Badge>Tour base</Badge>}
          </label>
        ))
      ) : (
        <p>Add physical fixtures to workspace inventory first.</p>
      )}
    </div>
  );
}
function InventoryDialog({ units, initial, locked, onSave, onClose }) {
  const [selected, setSelected] = useState(initial);
  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        onSave(selected);
      }}
    >
      <Selection
        units={units}
        selected={selected}
        locked={locked}
        onChange={setSelected}
      />
      <FormFooter onCancel={onClose} label="Save inventory selection" />
    </form>
  );
}
function PlacementForm({ unit, position, onSave }) {
  return (
    <form
      className="placement-form"
      onSubmit={(e) => {
        e.preventDefault();
        const f = new FormData(e.currentTarget);
        onSave(
          Object.fromEntries(
            ["x", "y", "z", "yaw"].map((key) => [key, Number(f.get(key))]),
          ),
        );
      }}
    >
      <p>
        Coordinates use the selected scan’s origin. X = right, Y = height, Z =
        depth; metres. Rotation is around Y.
      </p>
      <div className="field-grid">
        {["x", "y", "z", "yaw"].map((key) => (
          <Field
            key={key}
            label={`${key.toUpperCase()} ${key === "yaw" ? "(degrees)" : "(m)"}`}
          >
            <input
              required
              name={key}
              type="number"
              step="any"
              defaultValue={position?.[key] ?? 0}
            />
          </Field>
        ))}
      </div>
      <Button primary type="submit">
        Save placement for {unit.name}
      </Button>
    </form>
  );
}
function PatchRow({ unit, patch, onSave }) {
  return (
    <form
      className="patch-row"
      onSubmit={(e) => {
        e.preventDefault();
        const f = new FormData(e.currentTarget);
        onSave(Number(f.get("universe")), Number(f.get("address")));
      }}
    >
      <span>
        <strong>{unit.name}</strong>
        <small>{unit.footprint} channels</small>
      </span>
      <Field label="Universe">
        <input
          name="universe"
          type="number"
          min="1"
          required
          defaultValue={patch?.universe || 1}
        />
      </Field>
      <Field label="Address">
        <input
          name="address"
          type="number"
          min="1"
          max={513 - unit.footprint}
          required
          defaultValue={patch?.address || ""}
          placeholder="Unpatched"
        />
      </Field>
      <Button type="submit">Save patch</Button>
    </form>
  );
}
export default function Workspace({ ProgrammingPreview }) {
  const [state, setState] = useSharedState(workspaceKey, emptyWorkspace());
  const library = useVenueLibrary();
  const initialRoute = params().get("screen") || "overview";
  const [route, setRoute] = useState(aliases[initialRoute] || initialRoute);
  const [venueId, setVenueId] = useState(params().get("venueId") || "");
  const [loadoutId, setLoadoutId] = useState(params().get("loadoutId") || "");
  const [tourId, setTourId] = useState(params().get("tourId") || "");
  const [query, setQuery] = useState("");
  const [modal, setModal] = useState(null);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");
  const [tab, setTab] = useState("inventory");
  const loadout = state.loadouts.find((l) => l.id === loadoutId);
  const tour = state.tours.find((t) => t.id === tourId);
  const venue = library.venues.find((v) => v.id === venueId);
  const available = library.venues.filter(
    (v) => v.status === "ready" && v.setupStatus === "configured" && v.assetUrl,
  );
  const inbox = library.venues.filter((v) => v.setupStatus !== "configured");
  const filtered = (items) =>
    items.filter((v) => v.name.toLowerCase().includes(query.toLowerCase()));
  function go(next, ids = {}) {
    setRoute(aliases[next] || next);
    if (next === "upload") setVenueId("");
    setQuery("");
    setError("");
    setMessage("");
    if ("venueId" in ids) setVenueId(ids.venueId);
    if ("loadoutId" in ids) setLoadoutId(ids.loadoutId);
    if ("tourId" in ids) setTourId(ids.tourId);
    window.scrollTo(0, 0);
  }
  useEffect(() => {
    const p = new URLSearchParams();
    p.set("screen", route === "upload" && venueId ? "venue-detail" : route);
    if (params().get("popout") === "1") p.set("popout", "1");
    if (venueId) p.set("venueId", venueId);
    if (loadoutId) p.set("loadoutId", loadoutId);
    if (tourId) p.set("tourId", tourId);
    history.replaceState({}, "", `?${p}`);
    document.title = `${navigation.find((n) => n[0] === route)?.[1] || loadout?.name || venue?.name || "Workspace"} · Venue Volume`;
  }, [route, venueId, loadoutId, tourId, loadout?.name, venue?.name]);
  async function dispatch(action) {
    setError("");
    try {
      await setState((current) => transition(current, action, library.venues));
      setMessage("Saved in this browser.");
      return true;
    } catch (e) {
      setError(e.message);
      return false;
    }
  }
  function download(data, name) {
    const url = URL.createObjectURL(
      new Blob([JSON.stringify(data, null, 2)], { type: "application/json" }),
    );
    const a = document.createElement("a");
    a.href = url;
    a.download = name;
    a.click();
    URL.revokeObjectURL(url);
  }
  const heading = (title, description, actions) => (
    <div className="page-heading">
      <div>
        <span className="eyebrow">AFTERGLOW PRODUCTIONS / WORKSPACE</span>
        <h1>{title}</h1>
        <p>{description}</p>
      </div>
      <div className="heading-actions">{actions}</div>
    </div>
  );
  const newLoadout = (id = "") => {
    setVenueId(id);
    setModal({ kind: "loadout", venueId: id });
  };
  const openLoadout = (l) => {
    setTab("inventory");
    go("loadout", { loadoutId: l.id, venueId: l.venueId, tourId: l.tourId });
  };
  const listLoadouts = (items) =>
    items.length ? (
      <div className="workspace-cards">
        {filtered(items).map((l) => {
          const issues = readiness(state, l);
          return (
            <button
              className="workspace-card"
              key={l.id}
              onClick={() => openLoadout(l)}
            >
              <Layers size={22} />
              <h2>{l.name}</h2>
              <p>
                {library.venues.find((v) => v.id === l.venueId)?.name ||
                  l.scan.name}
              </p>
              <span>
                {inventoryIds(l).length} fixtures ·{" "}
                {Object.keys(l.placements).length} placed
              </span>
              <Badge tone={issues.length ? "amber" : "green"}>
                {issues.length ? "Needs preparation" : "Prepared for review"}
              </Badge>
              <small>
                {state.tours.find((t) => t.id === l.tourId)?.name ||
                  "Independent Load Out"}
              </small>
            </button>
          );
        })}
      </div>
    ) : (
      <Empty
        title="No Load Outs yet"
        detail="Choose an imported scan, then select and place fixtures for this room."
        action={
          <Button primary onClick={() => newLoadout(venue?.id)}>
            Create Load Out
          </Button>
        }
      />
    );
  function content() {
    if (
      programRoutes.includes(route) ||
      operationRoutes.includes(route) ||
      ["library", "fixture"].includes(route)
    ) {
      if (!loadout && !["library", "fixture"].includes(route))
        return chooseContext();
      return (
        <>
          <div className="callout">
            <p>
              Programming design preview · sample cue content, simulated output.
              Context: <strong>{loadout?.name || "Fixture profiles"}</strong>.
              Preparation is saved separately in your Load Out.
            </p>
          </div>
          <nav className="tabs" aria-label="Programming and operations">
            {(programRoutes.includes(route)
              ? [
                  ["presets", "Palettes & phasers"],
                  ["cues", "Cues"],
                  ["scripts", "Scripts"],
                ]
              : operationRoutes.includes(route)
                ? [
                    ["rehearsal", "Rehearsal"],
                    ["live", "Live console"],
                    ["outputs", "Connections"],
                    ["universe", "Universe monitor"],
                    ["recovery", "Recovery"],
                  ]
                : []
            ).map(([id, label]) => (
              <button
                key={id}
                className={
                  route === id || route === id.slice(0, -1) + "-editor"
                    ? "active"
                    : ""
                }
                onClick={() => go(id)}
              >
                {label}
              </button>
            ))}
          </nav>
          <ProgrammingPreview
            key={`${loadout?.id || "profiles"}:${route}`}
            embeddedRoute={route}
            onNavigate={go}
            context={
              loadout
                ? {
                    id: loadout.id,
                    name: loadout.name,
                    venue: loadout.scan.name,
                    fixtures: fixturesFor(state, loadout),
                  }
                : undefined
            }
          />
        </>
      );
    }
    switch (route) {
      case "overview":
        return (
          <>
            {heading(
              "A room. A rig. A plan.",
              "Prepare your inventory and placements here. Fine-tuning in visionOS comes in a later release.",
              <Button primary onClick={() => go("venues")}>
                Choose a scanned venue <ArrowRight size={16} />
              </Button>,
            )}
            <div className="workspace-hero">
              <div>
                <span className="eyebrow">YOUR NEXT LOAD OUT STARTS HERE</span>
                <h2>
                  One venue.
                  <br />
                  Every way to play it.
                </h2>
                <p>
                  Use the scanned room as your layout. Build as many Load Outs
                  as you need, or take shared inventory on Tour.
                </p>
                <Button onClick={() => newLoadout()}>
                  Create Load Out <Plus size={16} />
                </Button>
              </div>
              <div className="workflow-path">
                <span>01 / SCANNED VENUE</span>
                <strong>The room you’re working in</strong>
                <span>02 / LOAD OUT</span>
                <strong>Your fixtures, placement & patch</strong>
                <span>03 / TOUR · OPTIONAL</span>
                <strong>A shared rig. A Load Out at every stop.</strong>
              </div>
            </div>
            <div className="metrics">
              <Metric
                label="Scanned venues"
                value={available.length}
                detail={`${inbox.length} in the intake inbox`}
              />
              <Metric
                label="Load Outs"
                value={state.loadouts.length}
                detail="Independent fixture placements"
              />
              <Metric
                label="Physical fixtures"
                value={state.units.length}
                detail="Reusable across saved plans"
              />
              <Metric
                label="Tours"
                value={state.tours.length}
                detail="Shared inventory across venues"
              />
            </div>
            <Panel
              title="Continue preparing"
              subtitle="Choose a Load Out to manage inventory, placement and patching."
            >
              {listLoadouts(state.loadouts.slice(-3))}
            </Panel>
          </>
        );
      case "venues":
        return (
          <>
            {heading(
              "Scanned venues",
              "The shared library of rooms. Each venue can have several Load Outs.",
              <Button primary onClick={() => go("upload")}>
                <Upload size={16} />
                Upload venue movie
              </Button>,
            )}
            <IntakeConnection library={library} />
            <div className="toolbar">
              <SearchBox
                value={query}
                onChange={setQuery}
                placeholder="Search venues…"
              />
              <a className="text-link" href="/upload">
                Standalone movie upload <ArrowRight size={14} />
              </a>
            </div>
            <Panel
              title="Available scans"
              subtitle="Processed and imported venues available as Load Out layouts."
            >
              {available.length ? (
                <div className="workspace-cards">
                  {filtered(available).map((v) => (
                    <button
                      key={v.id}
                      className="workspace-card"
                      onClick={() => go("venue-detail", { venueId: v.id })}
                    >
                      <MapPin size={24} />
                      <h2>{v.name}</h2>
                      <p>{v.city || "Location not specified"}</p>
                      <Badge tone="green">Scan ready</Badge>
                      <small>
                        {
                          state.loadouts.filter((l) => l.venueId === v.id)
                            .length
                        }{" "}
                        Load Outs
                      </small>
                    </button>
                  ))}
                </div>
              ) : (
                <Empty
                  title={
                    library.loading ? "Loading scans…" : "No imported scans yet"
                  }
                  detail="Upload a venue movie, wait for processing, then import the scan from the inbox."
                  action={
                    <Button onClick={() => go("upload")}>Upload a movie</Button>
                  }
                />
              )}
              {available.length > 0 && !filtered(available).length && (
                <p className="panel-copy">No scans match your search.</p>
              )}
            </Panel>
            <Panel
              title="Venue inbox"
              subtitle="Capture now; import and set up later. Processing alone does not make a venue available for planning."
            >
              {filtered(inbox).map((v) => (
                <button
                  className="workspace-list-row"
                  key={v.id}
                  onClick={() => go("venue-detail", { venueId: v.id })}
                >
                  <span>
                    <strong>{v.name}</strong>
                    <small>{v.filename}</small>
                  </span>
                  <Badge tone={v.status === "failed" ? "amber" : "neutral"}>
                    {processingLabel(v)}
                  </Badge>
                  <ArrowRight size={17} />
                </button>
              ))}
              {!filtered(inbox).length && (
                <p className="panel-copy">
                  {query
                    ? "No matching uploads."
                    : "No movies awaiting import."}
                </p>
              )}
            </Panel>
          </>
        );
      case "upload":
        return (
          <>
            {heading(
              "Upload a venue movie",
              "Movie2Splat processes the recording into a scan. Import it before creating a Load Out.",
            )}
            <Panel title="Capture a room">
              <MovieUploadForm
                library={library}
                onReserved={(v) => {
                  setVenueId(v.id);
                  history.replaceState(
                    {},
                    "",
                    `?screen=venue-detail&venueId=${v.id}`,
                  );
                }}
                onQueued={(v) => {
                  library.refresh();
                  go("venue-detail", { venueId: v.id });
                }}
              />
            </Panel>
          </>
        );
      case "venue-detail":
        return (
          <>
            {heading(
              venue?.name || "Venue scan",
              "The room is shared. Inventory and placements belong to each Load Out.",
              <Button onClick={() => go("venues")}>All scanned venues</Button>,
            )}
            {venue ? (
              <>
                <VenueMovieDetail
                  key={venue.id}
                  library={library}
                  record={venue}
                  onOpen={() => library.refresh()}
                />
                {venue.status === "ready" &&
                  venue.setupStatus === "configured" && (
                    <Panel
                      title="Load Outs for this venue"
                      action={
                        <Button primary onClick={() => newLoadout(venue.id)}>
                          Create Load Out
                        </Button>
                      }
                    >
                      {listLoadouts(
                        state.loadouts.filter((l) => l.venueId === venue.id),
                      )}
                    </Panel>
                  )}
              </>
            ) : (
              <>
                <IntakeConnection library={library} />
                <Empty
                  title={
                    library.loading ? "Loading venue…" : "Venue unavailable"
                  }
                  detail="Reconnect to the intake service or select an existing scan from the venue library."
                />
              </>
            )}
          </>
        );
      case "inventory":
        return (
          <>
            {heading(
              "Fixture inventory",
              "Track physical units once. Select those units in Load Outs and Tour base inventory.",
              <Button primary onClick={() => setModal({ kind: "unit" })}>
                <Plus size={16} />
                Add physical fixture
              </Button>,
            )}
            <div className="toolbar">
              <SearchBox
                value={query}
                onChange={setQuery}
                placeholder="Search fixtures…"
              />
              <Button onClick={() => go("library")}>
                Browse fixture profiles
              </Button>
            </div>
            <div className="callout">
              <p>
                One record = one physical fixture. Saved plans may reuse it;
                simultaneous booking and availability scheduling are not
                implemented.
              </p>
            </div>
            {state.units.length ? (
              <Table
                headers={[
                  "Physical fixture",
                  "Profile / mode",
                  "Ownership",
                  "Used in",
                  "",
                ]}
                rows={filtered(state.units).map((u) => [
                  <span>
                    <strong>{u.name}</strong>
                    <small className="block">{u.id.slice(0, 8)}</small>
                  </span>,
                  `${u.model} · ${u.footprint} ch`,
                  u.ownership,
                  `${state.loadouts.filter((l) => inventoryIds(l).includes(u.id)).length} Load Outs`,
                  <Button
                    onClick={() => dispatch({ type: "remove-unit", id: u.id })}
                  >
                    Remove unused unit
                  </Button>,
                ])}
              />
            ) : (
              <Empty
                title="Your equipment starts here"
                detail="Add each physical fixture, then reuse it in plans without duplicating the unit."
                action={
                  <Button primary onClick={() => setModal({ kind: "unit" })}>
                    Add physical fixture
                  </Button>
                }
              />
            )}
          </>
        );
      case "loadouts":
        return (
          <>
            {heading(
              "Load Outs",
              "A Load Out is the selected fixture inventory and its placement inside one scanned venue.",
              <Button primary onClick={() => newLoadout()}>
                Create Load Out
              </Button>,
            )}
            <SearchBox
              value={query}
              onChange={setQuery}
              placeholder="Search Load Outs…"
            />
            {listLoadouts(state.loadouts)}
            {state.loadouts.length > 0 && !filtered(state.loadouts).length && (
              <p>No Load Outs match your search.</p>
            )}
          </>
        );
      case "loadout":
      case "patch":
      case "preflight":
      case "overrides":
        return renderLoadout();
      case "tours":
        return (
          <>
            {heading(
              "Tours",
              "Define a shared base rig, then prepare a dedicated Load Out for every venue stop.",
              <Button primary onClick={() => setModal({ kind: "tour" })}>
                Create Tour
              </Button>,
            )}
            {state.tours.length ? (
              <div className="workspace-cards">
                {state.tours.map((t) => (
                  <button
                    key={t.id}
                    className="workspace-card"
                    onClick={() => go("tour", { tourId: t.id })}
                  >
                    <Route size={24} />
                    <h2>{t.name}</h2>
                    <p>
                      {t.baseUnitIds.length} base fixtures · {t.stops.length}{" "}
                      venue stops
                    </p>
                    <span>
                      Open Tour <ArrowRight size={14} />
                    </span>
                  </button>
                ))}
              </div>
            ) : (
              <Empty
                title="Take your rig on the road"
                detail="You can also use independent Load Outs without a Tour."
                action={
                  <Button primary onClick={() => setModal({ kind: "tour" })}>
                    Create Tour
                  </Button>
                }
              />
            )}
          </>
        );
      case "tour":
        return tour ? (
          <>
            {heading(
              tour.name,
              "Base inventory travels with the Tour. Each stop has its own placement, patch and local additions.",
              <Button primary onClick={() => setModal({ kind: "stop" })}>
                Add venue stop
              </Button>,
            )}
            <Panel
              title="Base inventory"
              subtitle="Changes remain pending in existing Load Outs until reviewed."
              action={
                <Button onClick={() => setModal({ kind: "tour-inventory" })}>
                  Edit base inventory
                </Button>
              }
            >
              {tour.baseUnitIds.length ? (
                <div className="tour-base">
                  {tour.baseUnitIds.map((id) => (
                    <Badge key={id}>
                      {state.units.find((u) => u.id === id)?.name}
                    </Badge>
                  ))}
                </div>
              ) : (
                <p className="panel-copy">
                  Choose your shared touring fixtures from workspace inventory.
                </p>
              )}
            </Panel>
            <Panel
              title="Venue stops"
              subtitle="Revisiting a venue creates a separate stop and Load Out."
            >
              {tour.stops.map((stop, i) => {
                const l = state.loadouts.find((l) => l.id === stop.loadoutId);
                return (
                  <button
                    key={stop.id}
                    className="workspace-list-row"
                    onClick={() => openLoadout(l)}
                  >
                    <span className="stop-number">
                      {String(i + 1).padStart(2, "0")}
                    </span>
                    <span>
                      <strong>{l.scan.name}</strong>
                      <small>
                        {l.name} · {l.extraUnitIds.length} additional fixtures
                      </small>
                    </span>
                    <Badge
                      tone={readiness(state, l).length ? "amber" : "green"}
                    >
                      {readiness(state, l).length
                        ? "Needs preparation"
                        : "Prepared for review"}
                    </Badge>
                    <ArrowRight size={18} />
                  </button>
                );
              })}
              {!tour.stops.length && (
                <Empty
                  title="Choose the first venue"
                  detail="Each stop must use an imported scan. A dedicated Load Out is created with the current base inventory."
                  action={
                    <Button onClick={() => setModal({ kind: "stop" })}>
                      Add venue stop
                    </Button>
                  }
                />
              )}
            </Panel>
          </>
        ) : (
          <Empty
            title="Tour not found"
            action={<Button onClick={() => go("tours")}>All Tours</Button>}
          />
        );
      case "programming":
        return (
          <>
            {heading(
              "Programming",
              "Choose the Load Out whose fixtures and patch you want to program.",
            )}
            {chooseContext()}
            <Panel title="A consistent programming sequence">
              <p className="panel-copy">
                Fixture roles → palettes → cues → scripts → rehearsal. Current
                editors are design previews with sample cue content. Production
                programming inheritance across Tours remains to be implemented.
              </p>
            </Panel>
          </>
        );
      case "operations":
        return (
          <>
            {heading(
              "Rehearsal & live",
              "Review a Load Out before opening the simulated console.",
            )}
            {chooseContext(true)}
          </>
        );
      case "scene-review":
        return (
          <Suspense fallback={<p>Loading 3D review…</p>}>
            <VenueSceneReview />
          </Suspense>
        );
      case "assets":
        return (
          <>
            {heading(
              "Files",
              "Venue scan assets stay linked to their source recordings. Supporting drawings never create a room.",
            )}
            <Panel title="VisionOS venue saves">
              <p className="panel-copy">
                Import a saved venue and its fixtures to review in 3D, download
                a GLB, or export all eight isometric views.
              </p>
              <Button onClick={() => go("scene-review")}>Open 3D review</Button>
            </Panel>
            <Panel title="Scan assets">
              {available.map((v) => (
                <div className="workspace-list-row" key={v.id}>
                  <strong>{v.name}</strong>
                  <a className="button" href={v.assetUrl} download>
                    Download scan
                  </a>
                </div>
              ))}
              {!available.length && (
                <p className="panel-copy">
                  Import a processed scan to see its asset here.
                </p>
              )}
            </Panel>
            <Panel title="Supporting documents">
              <p className="panel-copy">
                CAD and document storage are planned. Room creation from CAD or
                blank floor plans is not offered.
              </p>
            </Panel>
          </>
        );
      case "activity":
        return (
          <>
            {heading(
              "Activity",
              "Changes made in this browser. This is not a server audit log.",
            )}
            <Panel title="Recent preparation">
              {state.activity.map((event) => (
                <div key={event.id} className="workspace-list-row">
                  <span>{event.description}</span>
                  <small>{new Date(event.at).toLocaleString()}</small>
                </div>
              ))}
              {!state.activity.length && (
                <p className="panel-copy">
                  Create inventory, a Tour or a Load Out to start a history.
                </p>
              )}
            </Panel>
          </>
        );
      case "team":
        return (
          <>
            {heading(
              "Team & access",
              "Workspace membership and permissions apply across venues, inventory, Load Outs and Tours.",
            )}
            <Panel title="Collaboration is not connected">
              <p className="panel-copy">
                This local prototype has no sign-in, invitations or role
                enforcement. Production roles will distinguish workspace
                administration, preparation, review and operation. There is no
                active invitation form.
              </p>
            </Panel>
          </>
        );
      case "settings":
        return (
          <>
            {heading(
              "Workspace settings",
              "Your preparation data is saved in this browser; movie intake uses the local service.",
            )}
            <Panel
              title="Export preparation data"
              subtitle="Includes fixture identities, Tours, Load Outs and scan references. Scan files and programming previews are separate."
            >
              <Button
                onClick={() => download(state, "venue-volume-workspace.json")}
              >
                <Download size={16} />
                Export workspace JSON
              </Button>
            </Panel>
            <Panel title="visionOS handoff">
              <p className="panel-copy">
                Prepare Load Outs in SaaS first. A later visionOS release will
                load the same identities and scan, then refine placement.
                Automatic device sync and a native import contract are not yet
                implemented.
              </p>
            </Panel>
          </>
        );
      case "billing":
        return (
          <>
            {heading(
              "Plan & billing",
              "Subscription management is not connected in this prototype.",
            )}
            <Panel title="Workspace usage">
              <dl>
                <dt>Scanned venues</dt>
                <dd>{available.length}</dd>
                <dt>Load Outs</dt>
                <dd>{state.loadouts.length}</dd>
                <dt>Tours</dt>
                <dd>{state.tours.length}</dd>
                <dt>Physical fixtures</dt>
                <dd>{state.units.length}</dd>
              </dl>
              <p className="panel-copy">
                Pricing, seats and storage limits are not defined. No payment
                details are collected.
              </p>
            </Panel>
          </>
        );
      default:
        return (
          <Empty
            title="Page not found"
            action={
              <Button onClick={() => go("overview")}>Workspace overview</Button>
            }
          />
        );
    }
  }
  function chooseContext(operations = false) {
    return (
      <Panel title="Select a Load Out">
        {state.loadouts.map((l) => (
          <div key={l.id} className="workspace-list-row">
            <span>
              <strong>{l.name}</strong>
              <small>{l.scan.name}</small>
            </span>
            <Button
              onClick={() => {
                setLoadoutId(l.id);
                setVenueId(l.venueId);
                setTourId(l.tourId);
                if (operations) {
                  setTab("review");
                  go("loadout");
                } else go("presets");
              }}
            >
              {operations ? "Review readiness" : "Open programming preview"}
            </Button>
          </div>
        ))}
        {!state.loadouts.length && (
          <Empty
            title="Prepare a Load Out first"
            detail="Choose a scan and select your inventory to establish the working context."
            action={
              <Button onClick={() => newLoadout()}>Create Load Out</Button>
            }
          />
        )}
      </Panel>
    );
  }
  function renderLoadout() {
    if (!loadout) return chooseContext();
    const units = fixturesFor(state, loadout);
    const changes = baseChanges(state, loadout);
    const issues = readiness(state, loadout);
    const activeTab =
      route === "patch" ? "patch" : route === "preflight" ? "review" : tab;
    const selectedScan = library.venues.find((v) => v.id === loadout.venueId);
    return (
      <>
        {heading(
          loadout.name,
          `${selectedScan?.name || loadout.scan.name} · ${state.tours.find((t) => t.id === loadout.tourId)?.name || "Independent Load Out"}`,
          <>
            <Button onClick={() => setModal({ kind: "copy" })}>
              Duplicate Load Out
            </Button>
            <Button
              onClick={() =>
                download({ ...loadout, fixtures: units }, "load-out.json")
              }
            >
              Export plan
            </Button>
          </>,
        )}
        <div className="loadout-source">
          <MapPin size={20} />
          <span>
            <strong>Layout: {loadout.scan.name}</strong>
            <small>
              Linked scan · {loadout.scan.id.slice(0, 8)} · positions in metres
            </small>
          </span>
          <Button
            onClick={() => go("venue-detail", { venueId: loadout.venueId })}
          >
            View venue
          </Button>
        </div>
        {(!selectedScan || library.error) && (
          <div className="callout warning">
            <p>
              The scan service is unavailable or this scan cannot be found. Your
              saved preparation is retained; verify the source before use.
            </p>
          </div>
        )}
        {!!(changes.added.length + changes.removed.length) && (
          <div className="callout warning">
            <div>
              <strong>Tour inventory has changed</strong>
              <p>
                {changes.added.length} new base fixtures;{" "}
                {changes.removed.length} removed from the base. Review before
                adopting.
              </p>
            </div>
            <Button onClick={() => setModal({ kind: "base-review" })}>
              Review base changes
            </Button>
          </div>
        )}
        <nav className="tabs" aria-label="Load Out workflow">
          {[
            ["inventory", "1 · Inventory"],
            ["placement", "2 · Placement"],
            ["patch", "3 · Patch"],
            ["review", "4 · Review"],
          ].map(([id, label]) => (
            <button
              key={id}
              className={activeTab === id ? "active" : ""}
              onClick={() => {
                setTab(id);
                setRoute("loadout");
              }}
            >
              {label}
            </button>
          ))}
        </nav>
        {activeTab === "inventory" && (
          <Panel
            title="Inventory for this Load Out"
            subtitle="Tour base fixtures and additions for this venue. Each physical unit can appear once."
            action={
              <Button
                primary
                onClick={() => setModal({ kind: "loadout-inventory" })}
              >
                Select fixtures
              </Button>
            }
          >
            {units.length ? (
              <Table
                headers={["Physical fixture", "Source", "Placement", ""]}
                rows={units.map((u) => [
                  <strong>{u.name}</strong>,
                  <Badge>
                    {loadout.baseUnitIds.includes(u.id)
                      ? "Tour base"
                      : loadout.tourId
                        ? "Venue addition"
                        : "Selected inventory"}
                  </Badge>,
                  loadout.placements[u.id] ? "Placed" : "Unplaced",
                  <Button
                    onClick={() => {
                      setModal({ kind: "vision-pro", unitId: u.id });
                    }}
                  >
                    Place in Vision Pro
                  </Button>,
                ])}
              />
            ) : (
              <Empty
                title="Choose fixtures for this room"
                detail="Select existing units from workspace inventory. This does not create or reserve more equipment."
                action={
                  <Button onClick={() => go("inventory")}>
                    Manage workspace inventory
                  </Button>
                }
              />
            )}
          </Panel>
        )}
        {activeTab === "placement" && (
          <div className="loadout-placement">
            <Panel
              title="Placement plan"
              subtitle="Coordinate plan tied to the scan. The browser does not yet render Gaussian splats."
            >
              <div className="coordinate-plan">
                <svg
                  viewBox="0 0 600 380"
                  role="img"
                  aria-label="Fixture positions, schematic top view"
                >
                  <defs>
                    <pattern
                      id="grid"
                      width="30"
                      height="30"
                      patternUnits="userSpaceOnUse"
                    >
                      <path
                        d="M 30 0 L 0 0 0 30"
                        fill="none"
                        stroke="#d7decc"
                        strokeWidth="1"
                      />
                    </pattern>
                  </defs>
                  <rect width="600" height="380" fill="url(#grid)" />
                  <path
                    d="M300 20 V360 M20 190 H580"
                    stroke="#82996d"
                    strokeDasharray="4 4"
                  />
                  <text x="310" y="180" fill="#687d59" fontSize="12">
                    Scan origin
                  </text>
                  {units
                    .filter((u) => loadout.placements[u.id])
                    .map((u, i) => {
                      const p = loadout.placements[u.id];
                      const extent = Math.max(
                        10,
                        ...Object.values(loadout.placements).flatMap((p) => [
                          Math.abs(p.x),
                          Math.abs(p.z),
                        ]),
                      );
                      const scale = 150 / extent;
                      return (
                        <g key={u.id}>
                          <circle
                            cx={300 + p.x * scale}
                            cy={190 + p.z * scale}
                            r="10"
                            fill="#37563c"
                          />
                          <text
                            x={314 + p.x * scale}
                            y={194 + p.z * scale}
                            fontSize="12"
                            fill="#243c28"
                          >
                            {i + 1}
                          </text>
                        </g>
                      );
                    })}
                </svg>
                <p>
                  Schematic X/Z projection · auto-fit · no room boundaries
                  inferred
                </p>
              </div>
              <a className="button" href={loadout.scan.assetUrl} download>
                Download linked scan
              </a>
              <label className="check-line">
                <input
                  type="checkbox"
                  checked={loadout.scanReviewed}
                  onChange={(e) =>
                    dispatch({
                      type: "review-scan",
                      id: loadout.id,
                      reviewed: e.target.checked,
                    })
                  }
                />
                I reviewed the scan’s scale and coordinate origin externally.
              </label>
            </Panel>
            <Panel
              title="Fixture placement"
              subtitle="Select a fixture to enter exact coordinates. Returning it to inventory preserves its identity and patch."
            >
              {units.map((u, i) => (
                <div className="placement-unit" key={u.id}>
                  <strong>{u.name}</strong>
                  <small>
                    {loadout.placements[u.id]
                      ? `X ${loadout.placements[u.id].x} · Y ${loadout.placements[u.id].y} · Z ${loadout.placements[u.id].z} m`
                      : "Unplaced"}
                  </small>
                  <div>
                    <Button
                      onClick={() =>
                        setModal({ kind: "placement", unitId: u.id })
                      }
                    >
                      Edit position
                    </Button>
                    <Button
                      onClick={() =>
                        setModal({ kind: "vision-pro", unitId: u.id })
                      }
                    >
                      Place in Vision Pro
                    </Button>
                    {loadout.placements[u.id] && (
                      <Button
                        onClick={() =>
                          dispatch({
                            type: "unplace",
                            id: loadout.id,
                            unitId: u.id,
                          })
                        }
                      >
                        Return to inventory
                      </Button>
                    )}
                  </div>
                </div>
              ))}
              {!units.length && (
                <p className="panel-copy">Select fixture inventory first.</p>
              )}
            </Panel>
          </div>
        )}
        {activeTab === "patch" && (
          <Panel
            title="DMX patch"
            subtitle="Addresses belong to this Load Out. Conflicts are reported in Review."
          >
            {units.map((u) => (
              <PatchRow
                key={`${loadout.id}:${u.id}`}
                unit={u}
                patch={loadout.patch[u.id]}
                onSave={(universe, address) =>
                  dispatch({
                    type: "patch",
                    id: loadout.id,
                    unitId: u.id,
                    universe,
                    address,
                  })
                }
              />
            ))}
            {!units.length && (
              <p className="panel-copy">
                Select fixture inventory before patching.
              </p>
            )}
          </Panel>
        )}
        {activeTab === "review" && (
          <>
            <Panel
              title={
                issues.length ? "Preparation checklist" : "Prepared for review"
              }
              subtitle="Planning checks only. This does not certify a venue, rig or hardware connection."
            >
              {issues.length ? (
                <ul className="readiness-list">
                  {issues.map((issue, i) => (
                    <li key={i}>{issue}</li>
                  ))}
                </ul>
              ) : (
                <p className="panel-copy">
                  Inventory, placements and patch pass the local planning
                  checks.
                </p>
              )}
              <div className="toolbar">
                <Button onClick={() => go("presets")}>
                  Programming preview
                </Button>
                <Button
                  disabled={!!issues.length || !selectedScan || !!library.error}
                  onClick={() => go("rehearsal")}
                >
                  Open simulated rehearsal
                </Button>
              </div>
            </Panel>
            <Panel title="Prepare here. Fine-tune in visionOS later.">
              <p className="panel-copy">
                SaaS owns fixture selection, placement and patching in this
                release. Native Load Out sync and spatial refinement are
                planned; exporting a plan does not send it to a headset.
              </p>
            </Panel>
          </>
        )}
      </>
    );
  }
  function dialog() {
    const kind = modal.kind;
    const close = () => {
      setModal(null);
      setError("");
    };
    if (kind === "tour-inventory" || kind === "loadout-inventory")
      return (
        <InventoryDialog
          units={state.units}
          initial={
            kind === "tour-inventory" ? tour.baseUnitIds : inventoryIds(loadout)
          }
          locked={kind === "loadout-inventory" ? loadout.baseUnitIds : []}
          onClose={close}
          onSave={async (ids) => {
            if (
              await dispatch({
                type:
                  kind === "tour-inventory" ? "tour-base" : "loadout-inventory",
                id: kind === "tour-inventory" ? tour.id : loadout.id,
                unitIds: ids,
              })
            )
              close();
          }}
        />
      );
    if (kind === "vision-pro") {
      const unit = state.units.find((u) => u.id === modal.unitId);
      return <VisionProHandoff loadout={loadout} unit={unit} />;
    }
    if (kind === "placement") {
      const unit = state.units.find((u) => u.id === modal.unitId);
      return (
        <PlacementForm
          unit={unit}
          position={loadout.placements[unit.id]}
          onSave={async (position) => {
            if (
              await dispatch({
                type: "place",
                id: loadout.id,
                unitId: unit.id,
                position,
              })
            )
              close();
          }}
        />
      );
    }
    if (kind === "base-review") {
      const changes = baseChanges(state, loadout);
      const names = (ids) =>
        ids
          .map((id) => state.units.find((u) => u.id === id)?.name)
          .join(", ") || "None";
      return (
        <>
          <p>Add to base: {names(changes.added)}</p>
          <p>Remove from base: {names(changes.removed)}</p>
          <div className="callout">
            <p>
              Removed base fixtures will remain as venue additions, preserving
              their placement and patch. You can return them to inventory and
              remove them separately.
            </p>
          </div>
          <Button
            primary
            onClick={async () => {
              if (await dispatch({ type: "adopt-base", id: loadout.id }))
                close();
            }}
          >
            Apply reviewed base inventory
          </Button>
        </>
      );
    }
    if (
      ["loadout", "stop"].includes(kind) &&
      (!available.length || !!library.error)
    )
      return (
        <Empty
          title="An imported scan is required"
          detail="Open the venue inbox to import a completed scan, or upload a new movie. A blank room cannot be created."
          action={
            <Button
              onClick={() => {
                close();
                go("venues");
              }}
            >
              Open scanned venues
            </Button>
          }
        />
      );
    return (
      <form
        onSubmit={async (e) => {
          e.preventDefault();
          const f = Object.fromEntries(new FormData(e.currentTarget));
          const id = uid();
          let action;
          if (kind === "unit")
            action = {
              type: "add-unit",
              id,
              ...f,
              footprint: Number(f.footprint),
            };
          if (kind === "tour") action = { type: "add-tour", id, name: f.name };
          if (kind === "loadout") action = { type: "add-loadout", id, ...f };
          if (kind === "stop")
            action = {
              type: "add-stop",
              id,
              loadoutId: uid(),
              tourId: tour.id,
              ...f,
            };
          if (kind === "copy")
            action = {
              type: "copy-loadout",
              id: loadout.id,
              newId: id,
              name: f.name,
            };
          if (await dispatch(action)) {
            close();
            if (kind === "tour") go("tour", { tourId: id });
            if (kind === "loadout" || kind === "copy") {
              setTab("inventory");
              go("loadout", {
                loadoutId: id,
                venueId: f.venueId || loadout.venueId,
              });
            }
          }
        }}
      >
        <Field
          label={
            kind === "unit"
              ? "Physical fixture name"
              : kind === "tour"
                ? "Tour name"
                : "Load Out name"
          }
        >
          <input
            name="name"
            required
            maxLength="160"
            defaultValue={kind === "copy" ? `${loadout.name} copy` : ""}
            placeholder={
              kind === "unit"
                ? "Wash 01"
                : kind === "tour"
                  ? "Fall Tour 2026"
                  : "Main stage · evening setup"
            }
          />
        </Field>
        {["loadout", "stop"].includes(kind) && (
          <Field label="Scanned venue">
            <select
              name="venueId"
              required
              defaultValue={modal.venueId || available[0]?.id}
            >
              {available.map((v) => (
                <option key={v.id} value={v.id}>
                  {v.name}
                </option>
              ))}
            </select>
          </Field>
        )}
        {kind === "stop" && (
          <p>
            A dedicated Load Out is created with {tour.baseUnitIds.length} base
            fixtures, initially unplaced and unpatched.
          </p>
        )}
        {kind === "copy" && (
          <p>
            Copies this plan in the same venue using the same physical fixture
            IDs. Creates an independent Load Out; does not add a Tour stop or
            create equipment.
          </p>
        )}
        {kind === "unit" && (
          <>
            <Field label="Fixture profile / model">
              <input
                name="model"
                required
                maxLength="160"
                placeholder="Manufacturer and model"
              />
            </Field>
            <Field label="DMX footprint (channels)">
              <input
                name="footprint"
                type="number"
                min="1"
                max="512"
                required
                defaultValue="8"
              />
            </Field>
            <Field label="Fixture role">
              <input name="role" placeholder="e.g. Front wash" />
            </Field>
            <Field label="Ownership">
              <select name="ownership">
                <option>Owned</option>
                <option>Rented</option>
                <option>Venue supplied</option>
              </select>
            </Field>
            <p>
              Manual profile metadata for planning. Verify a real fixture
              profile and mode before hardware use.
            </p>
          </>
        )}
        <FormFooter
          onCancel={close}
          label={
            kind === "unit"
              ? "Add fixture"
              : kind === "tour"
                ? "Create Tour"
                : kind === "stop"
                  ? "Add stop & Load Out"
                  : kind === "copy"
                    ? "Duplicate Load Out"
                    : "Create Load Out"
          }
        />
      </form>
    );
  }
  const section =
    route === "tour"
      ? "tours"
      : ["loadout", "patch", "preflight", "overrides"].includes(route)
        ? "loadouts"
        : ["venue-detail", "upload"].includes(route)
          ? "venues"
          : programRoutes.includes(route)
            ? "programming"
            : operationRoutes.includes(route)
              ? "operations"
              : route;
  if (
    params().get("popout") === "1" &&
    loadout &&
    ["live", "rehearsal"].includes(route)
  )
    return (
      <div className="app console-popout">
        <main className="live-page">
          <ProgrammingPreview
            key={loadout.id}
            embeddedRoute={route}
            onNavigate={go}
            context={{
              id: loadout.id,
              name: loadout.name,
              venue: loadout.scan.name,
              fixtures: fixturesFor(state, loadout),
            }}
          />
        </main>
      </div>
    );
  return (
    <div className="workspace-product app">
      <div className="workspace-notice">
        LOCAL PRODUCT PROTOTYPE{" "}
        <span>
          Preparation saved in this browser · movie processing uses the intake
          service
        </span>
      </div>
      <div className="workspace-layout">
        <aside className="workspace-nav">
          <a className="workspace-brand" href="/">
            venue
            <br />
            <b>volume</b>
            <span>PRODUCTION WORKSPACE</span>
          </a>
          <nav aria-label="Workspace navigation">
            {navigation.map(([id, label]) => (
              <button
                key={id}
                aria-current={section === id ? "page" : undefined}
                onClick={() => go(id)}
              >
                {label}
                {id === "venues" && inbox.length > 0 && (
                  <small>{inbox.length}</small>
                )}
              </button>
            ))}
          </nav>
          <p>
            Prepare in SaaS.
            <br />
            Refine in visionOS later.
          </p>
        </aside>
        <div className="workspace-body">
          <header className="workspace-topbar">
            <span>
              Afterglow Productions <span>/</span>{" "}
              {navigation.find((n) => n[0] === section)?.[1] || "Workspace"}
            </span>
            <Badge>Local workspace</Badge>
          </header>
          <main>
            {error && !modal && (
              <div className="callout warning" role="alert">
                {error}
              </div>
            )}
            {message && (
              <div className="workspace-save" role="status">
                {message}
              </div>
            )}
            {content()}
          </main>
        </div>
      </div>
      {modal && (
        <Dialog
          title={
            {
              unit: "Add physical fixture",
              tour: "Create Tour",
              loadout: "Create Load Out",
              stop: "Add venue stop",
              copy: "Duplicate Load Out",
              "tour-inventory": "Tour base inventory",
              "loadout-inventory": "Load Out inventory",
              placement: "Fixture placement",
              "vision-pro": "Place fixture in Vision Pro",
              "base-review": "Review Tour base changes",
            }[modal.kind]
          }
          onClose={() => {
            setModal(null);
            setError("");
          }}
        >
          {error && (
            <div className="callout warning" role="alert">
              {error}
            </div>
          )}
          {dialog()}
        </Dialog>
      )}
    </div>
  );
}
