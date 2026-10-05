import React, { useCallback, useEffect, useRef, useState } from "react";
import { zip, strToU8 } from "fflate";
import {
  sceneFromSave,
  exportGLB,
  loadGLB,
  disposeScene,
  ISOMETRIC_VIEWS,
  readExportedGLB,
} from "./venue-scene";
import { sceneStorage } from "./scene-storage";
import SceneViewer from "./SceneViewer";
import "./venue-scene.css";

const fileName = (name) =>
  name.replace(/[^a-z0-9_-]+/gi, "-").slice(0, 80) || "venue";
function download(blob, name) {
  const url = URL.createObjectURL(blob),
    a = document.createElement("a");
  a.href = url;
  a.download = name;
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 30000);
}
export default function VenueSceneReview() {
  const [snapshots, setSnapshots] = useState([]),
    [active, setActive] = useState(null),
    [busy, setBusy] = useState(""),
    [error, setError] = useState("");
  const [ghost, setGhost] = useState(true),
    [hideCeiling, setHideCeiling] = useState(true),
    [hideForegroundWalls, setHideForegroundWalls] = useState(true),
    [view, setView] = useState(ISOMETRIC_VIEWS[0].id),
    [viewer, setViewer] = useState(null);
  const mounted = useRef(true),
    current = useRef(null);
  const viewerReady = useCallback((value) => setViewer(value), []),
    viewerError = useCallback((message) => setError(message), []);
  async function refresh() {
    const records = await sceneStorage("list");
    if (mounted.current)
      setSnapshots(records.sort((a, b) => b.created - a.created));
  }
  useEffect(() => {
    mounted.current = true;
    refresh().catch(() =>
      setError(
        "Browser storage is unavailable. You can still import and download a scene.",
      ),
    );
    return () => {
      mounted.current = false;
      disposeScene(current.current?.model);
    };
  }, []);
  function display(next) {
    if (!mounted.current) {
      disposeScene(next.model);
      return;
    }
    const previous = current.current;
    current.current = next;
    setActive(next);
    setView(next.spawn ? "walk" : ISOMETRIC_VIEWS[0].id);
    // React cleans up the old viewer before releasing its scene resources.
    if (previous) setTimeout(() => disposeScene(previous.model), 0);
  }
  async function importSave(file) {
    if (!file) return;
    setError("");
    setBusy("Reading save…");
    let model;
    try {
      const result = await sceneFromSave(file, (message) => {
        if (mounted.current) setBusy(message);
      });
      model = result.scene;
      setBusy("Building portable 3D file…");
      const bytes = await exportGLB(model);
      const record = {
        id: crypto.randomUUID(),
        name: result.save.setup.name,
        roomName:
          result.save.room.manifest.title || result.save.room.manifest.id,
        setupID: result.save.setup.id,
        spawn: model.userData.spawn,
        ceilingTriangles: model.userData.ceilingTriangles,
        wallTrianglesBySide: model.userData.wallTrianglesBySide,
        roomID: result.save.setup.roomID,
        created: Date.now(),
        fixtures: result.save.setup.placements.fixtures.map((f) => ({
          id: f.id,
          name: f.name,
          assetID: f.assetID,
        })),
        glb: new Blob([bytes], { type: "model/gltf-binary" }),
      };
      if (!mounted.current) {
        disposeScene(model);
        return;
      }
      try {
        await sceneStorage("put", record);
        await refresh();
      } catch {
        setError(
          "The scene is ready, but browser storage is full or unavailable. Download the GLB before leaving this page.",
        );
      }
      display({ ...record, model });
      model = null;
    } catch (e) {
      if (mounted.current) setError(e.message);
      disposeScene(model);
    } finally {
      if (mounted.current) setBusy("");
    }
  }
  async function importGLB(file) {
    if (!file) return;
    setError("");
    setBusy("Opening exported GLB…");
    let next;
    try {
      next = {
        ...(await readExportedGLB(file)),
        id: crypto.randomUUID(),
        created: Date.now(),
      };
      if (!mounted.current) {
        disposeScene(next.model);
        return;
      }
      const { model, ...record } = next;
      try {
        await sceneStorage("put", record);
        await refresh();
      } catch {
        setError(
          "The GLB is open, but browser storage is full or unavailable. Keep your original file.",
        );
      }
      display(next);
      next = null;
    } catch (e) {
      if (mounted.current) setError(e.message);
      disposeScene(next?.model);
    } finally {
      if (mounted.current) setBusy("");
    }
  }
  async function open(record) {
    setError("");
    setBusy("Opening saved 3D snapshot…");
    try {
      display({
        ...record,
        model: await loadGLB(await record.glb.arrayBuffer()),
      });
    } catch (e) {
      if (mounted.current) setError(`Could not open snapshot: ${e.message}`);
    } finally {
      if (mounted.current) setBusy("");
    }
  }
  async function images(all) {
    setError("");
    setBusy("Rendering isometric views…");
    try {
      if (!all) {
        const imageView =
          ISOMETRIC_VIEWS.find((v) => v.id === view)?.id ||
          ISOMETRIC_VIEWS[0].id;
        const png = await viewer.capture(imageView, active.name);
        if (mounted.current)
          download(png, `${fileName(active.name)}-${imageView}.png`);
      } else {
        const files = {};
        for (const v of ISOMETRIC_VIEWS) {
          if (!mounted.current) return;
          setBusy(`Rendering ${v.id.replaceAll("-", " ")}…`);
          files[`${v.id}.png`] = new Uint8Array(
            await (await viewer.capture(v.id, active.name)).arrayBuffer(),
          );
          await new Promise((resolve) => setTimeout(resolve, 0));
        }
        files["views.json"] = strToU8(
          JSON.stringify(
            {
              name: active.name,
              setupID: active.setupID,
              roomID: active.roomID,
              projection: "orthographic isometric",
              units: "meters",
              frontAxis: "-Z",
              upAxis: "Y",
              transparentVenue: ghost,
              ceilingHidden: hideCeiling,
              foregroundWallsHidden: hideForegroundWalls,
              resolution: [1600, 1200],
              views: ISOMETRIC_VIEWS,
            },
            null,
            2,
          ),
        );
        const zipped = await new Promise((resolve, reject) =>
          zip(files, { level: 0 }, (err, data) =>
            err ? reject(err) : resolve(data),
          ),
        );
        if (mounted.current)
          download(
            new Blob([zipped], { type: "application/zip" }),
            `${fileName(active.name)}-isometric-views.zip`,
          );
      }
    } catch (e) {
      setError(`Export failed: ${e.message}`);
    } finally {
      setBusy("");
    }
  }
  async function remove(record) {
    setError("");
    try {
      await sceneStorage("delete", record.id);
      await refresh();
    } catch {
      setError("Could not remove this saved snapshot.");
    }
  }
  return (
    <section className="venue-review" aria-label="Venue 3D review">
      <header className="venue-review-heading">
        <div>
          <p className="eyebrow">VISIONOS → WEB</p>
          <h1>3D review</h1>
          <p>
            Review a saved venue and its Load Out. Share a portable 3D file or
            all eight isometric views.
          </p>
        </div>
        <label className={`button primary ${busy ? "disabled" : ""}`}>
          Import visionOS save
          <input
            aria-label="Import visionOS save"
            type="file"
            accept=".venuevolume"
            disabled={!!busy}
            onChange={(e) => {
              importSave(e.target.files[0]);
              e.target.value = "";
            }}
          />
        </label>
      </header>
      <label className={`button venue-open-glb ${busy ? "disabled" : ""}`}>
        Open exported GLB
        <input
          aria-label="Open exported GLB"
          type="file"
          accept=".glb"
          disabled={!!busy}
          onChange={(e) => {
            importGLB(e.target.files[0]);
            e.target.value = "";
          }}
        />
      </label>
      <p className="venue-review-note">
        In Vision Pro, choose <strong>Export save</strong>, then select the
        .venuevolume file here. Snapshots are stored in this browser; importing
        creates a review copy of the saved Load Out.
      </p>
      {busy && (
        <p role="status" className="venue-review-status">
          {busy}
        </p>
      )}
      {error && (
        <p role="alert" className="venue-review-error">
          {error}
        </p>
      )}
      {active ? (
        <>
          <div className="venue-review-toolbar">
            <div>
              <h2>{active.name}</h2>
              <p>
                {active.roomName} · {active.fixtures.length} fixtures ·
                read-only snapshot
              </p>
            </div>
            <div className="venue-review-actions">
              <button
                className="button"
                disabled={!!busy}
                onClick={() =>
                  download(active.glb, `${fileName(active.name)}.glb`)
                }
              >
                Download 3D (.glb)
              </button>
              <button
                className="button primary"
                disabled={!!busy || !viewer}
                onClick={() => images(true)}
              >
                Export all 8 views
              </button>
            </div>
          </div>
          <div className="venue-review-stage" aria-busy={!!busy}>
            <SceneViewer
              model={active.model}
              ghost={ghost}
              hideCeiling={hideCeiling}
              hideForegroundWalls={hideForegroundWalls}
              spawn={active.spawn}
              view={view}
              onReady={viewerReady}
              onError={viewerError}
            />
            <aside>
              <h3>Navigation</h3>
              <button
                className="button"
                disabled={!!busy || !viewer || !active.spawn}
                aria-pressed={view === "walk"}
                onClick={() => {
                  setView("walk");
                  viewer?.walk();
                }}
              >
                Walk from spawn
              </button>
              <p className="venue-small">
                Walk starts at the saved spawn point and heading. Click the
                scene to look, use W/A/S/D to move, and Esc to release the
                pointer.
              </p>
              <h3>Isometric views</h3>
              <div className="venue-view-grid">
                {ISOMETRIC_VIEWS.map((v) => (
                  <button
                    key={v.id}
                    disabled={!!busy}
                    aria-pressed={view === v.id}
                    onClick={() => {
                      setView(v.id);
                      viewer?.fit(v.id);
                    }}
                  >
                    {v.id.replaceAll("-", " ")}
                  </button>
                ))}
              </div>
              <label className="venue-ghost">
                <input
                  type="checkbox"
                  checked={hideCeiling}
                  disabled={!!busy || !active.ceilingTriangles}
                  onChange={(e) => setHideCeiling(e.target.checked)}
                />{" "}
                Hide ceiling {active.ceilingTriangles ? "" : "(none detected)"}
              </label>
              <label className="venue-ghost">
                <input
                  type="checkbox"
                  checked={hideForegroundWalls}
                  disabled={!!busy || !Object.values(active.wallTrianglesBySide || {}).some(Boolean)}
                  onChange={(e) => setHideForegroundWalls(e.target.checked)}
                />{" "}
                Hide foreground walls {Object.values(active.wallTrianglesBySide || {}).some(Boolean) ? "" : "(none detected)"}
              </label>
              <label className="venue-ghost">
                <input
                  type="checkbox"
                  checked={ghost}
                  disabled={!!busy}
                  onChange={(e) => setGhost(e.target.checked)}
                />{" "}
                See fixtures through venue
              </label>
              <button
                className="button"
                disabled={!!busy || !viewer}
                onClick={() => images(false)}
              >
                {ISOMETRIC_VIEWS.some((v) => v.id === view)
                  ? "Export selected view (.png)"
                  : "Export upper front right (.png)"}
              </button>
              <h3>Fixtures</h3>
              <p className="venue-small">
                Select a fixture to inspect its model.
              </p>
              <div className="venue-fixture-list">
                {active.fixtures.map((f) => (
                  <button
                    key={f.id}
                    disabled={!!busy || !viewer}
                    onClick={() => {
                      setView("focus");
                      viewer?.focus(f.id);
                    }}
                  >
                    {f.name}
                  </button>
                ))}
              </div>
              <button
                className="button"
                disabled={!!busy || !viewer}
                onClick={() => {
                  setView(ISOMETRIC_VIEWS[0].id);
                  viewer?.fit(ISOMETRIC_VIEWS[0].id);
                }}
              >
                Fit entire venue
              </button>
            </aside>
          </div>
          <p className="venue-review-note">
            Isometric: drag to orbit · scroll to zoom · right-drag to pan. Walk:
            click the scene, W/A/S/D to move, Esc to release. PNGs use the
            selected venue transparency; the GLB retains the full venue
            materials. Exports preserve placement and saved pan/tilt. Continuous
            motors use their rest phase; live lighting, beams and cues are not
            baked.
          </p>
        </>
      ) : (
        <div className="venue-review-empty">
          <span aria-hidden="true">◇</span>
          <h2>Your venue, ready to review</h2>
          <p>
            Import a visionOS save to see the room and the actual fixture models
            together.
          </p>
          <p>
            USDZ venues and native scanned meshes are supported. Movie2Splat PLY
            previews are not supported here yet.
          </p>
        </div>
      )}
      <section className="venue-snapshots">
        <h2>Saved 3D snapshots</h2>
        <p className="venue-small">
          Local to this browser. Download GLB files for sharing or backup.
          Re-import a newer save after making changes in Vision Pro.
        </p>
        {!snapshots.length && <p>No snapshots yet.</p>}
        {snapshots.map((record) => (
          <div className="venue-snapshot" key={record.id}>
            <div>
              <strong>{record.name}</strong>
              <p>
                {record.roomName} · {record.fixtures.length} fixtures ·{" "}
                {new Date(record.created).toLocaleString()}
              </p>
            </div>
            <button
              className="button"
              disabled={!!busy}
              onClick={() => open(record)}
            >
              Open snapshot
            </button>
            <button
              className="button"
              disabled={!!busy}
              onClick={() => remove(record)}
            >
              Remove saved copy
            </button>
          </div>
        ))}
      </section>
    </section>
  );
}
