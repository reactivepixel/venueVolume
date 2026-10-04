import React, { useEffect, useRef, useState } from "react";
import { ArrowLeft, ArrowRight, Building2, CheckCircle2, Film, Upload } from "lucide-react";
import { Badge, Button, Field, Panel } from "./components";
import { formatBytes, movieAccept, movieError, processingLabel, uploadMovie, useVenueLibrary, venueRequest } from "./venue-api";
import "./venue-movies.css";

export function IntakeConnection({ library }) {
  if (!library.error) return null;
  return <div className="callout warning" role="alert">
    <div><strong>Venue intake is unavailable</strong><p>{library.error}</p></div>
    <Button onClick={library.refresh}>Reconnect</Button>
  </div>;
}

export function MovieUploadForm({ library, show = "", templates = [], resumeRecord, onReserved, onQueued }) {
  const [file, setFile] = useState(null);
  const [name, setName] = useState(resumeRecord?.name || "");
  const [city, setCity] = useState(resumeRecord?.city || "");
  const [template, setTemplate] = useState(resumeRecord?.template || templates[0] || "");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [progress, setProgress] = useState(0);
  const [reserved, setReserved] = useState(resumeRecord || null);
  const attempt = useRef({ id: resumeRecord?.id || crypto.randomUUID(), details: null });
  const controller = useRef(null);
  const deferred = !show && !resumeRecord?.show;
  const uploadingElsewhere = resumeRecord?.status === "uploading" && !busy;
  useEffect(() => {
    if (!busy) return;
    const warn = (event) => { event.preventDefault(); event.returnValue = ""; };
    window.addEventListener("beforeunload", warn);
    return () => window.removeEventListener("beforeunload", warn);
  }, [busy]);
  useEffect(() => () => controller.current?.abort(), []);

  function choose(next) {
    const problem = movieError(next, library.maxUploadBytes);
    setError(problem);
    setFile(problem ? null : next);
  }

  async function submit(event) {
    event.preventDefault();
    if (busy) return;
    const problem = movieError(file, library.maxUploadBytes);
    if (problem) { setError(problem); return; }
    if (reserved && (reserved.filename !== file.name || reserved.size !== file.size)) {
      setError(`Choose the original movie: ${reserved.filename} (${formatBytes(reserved.size)}).`);
      return;
    }
    setBusy(true); setError(""); setProgress(0);
    controller.current = new AbortController();
    let record = reserved;
    try {
      if (!record) {
        // Keep the same ID and exact payload when a create response is lost.
        attempt.current.details ||= { idempotencyKey: attempt.current.id, filename: file.name,
          size: file.size, name: name.trim(), city: city.trim(), show, template: show ? template : "" };
        record = await venueRequest("", { method: "POST", body: JSON.stringify(attempt.current.details), signal: controller.current.signal });
        setReserved(record);
        onReserved?.(record);
      } else {
        record = await venueRequest(`/${record.id}`, { signal: controller.current.signal });
      }
      if (["queued", "processing", "ready", "failed"].includes(record.status)) {
        onQueued(record); return;
      }
      if (record.filename !== file.name || record.size !== file.size) {
        throw new Error(`Choose the original movie: ${record.filename} (${formatBytes(record.size)}).`);
      }
      const uploaded = await uploadMovie(record.id, file, setProgress, controller.current.signal);
      library.refresh();
      onQueued(uploaded);
    } catch (failure) {
      setError(failure.name === "AbortError" ? "Upload cancelled. You can try again." : failure.message);
      library.refresh();
    } finally {
      setBusy(false);
    }
  }

  return <form className="movie-upload-form" onSubmit={submit} aria-label="Upload a venue movie">
    <IntakeConnection library={library} />
    {resumeRecord && <p>Resume the upload for <strong>{resumeRecord.name}</strong> using {resumeRecord.filename}.</p>}
    <fieldset disabled={busy || uploadingElsewhere}>
      <label className={`movie-dropzone ${file ? "has-movie" : ""}`}
        onDragOver={(event) => { event.preventDefault(); }}
        onDrop={(event) => { event.preventDefault(); if (!busy && !uploadingElsewhere) choose(event.dataTransfer.files?.[0]); }}>
        <span className="movie-drop-icon"><Film size={30} strokeWidth={1.4} /></span>
        <strong>{file ? file.name : "Bring the room into Venue Volume."}</strong>
        <span>{file ? `${formatBytes(file.size)} · Ready to upload` : "Drop a walkthrough movie here, or choose a file."}</span>
        <input type="file" accept={movieAccept} aria-label="Venue movie" onChange={(event) => choose(event.target.files?.[0])} />
        <small>MOV, MP4 or M4V · Up to {formatBytes(library.maxUploadBytes)}</small>
      </label>
      {!resumeRecord && <>
        <Field label={deferred ? "Venue name (optional)" : "Venue name"} hint={deferred ? "Leave blank to use the movie filename. You can rename it during setup." : undefined}>
          <input value={name} onChange={(event) => setName(event.target.value)} required={!deferred} maxLength={160} disabled={!!reserved} placeholder="e.g. The Glasshouse" />
        </Field>
        {!deferred && <div className="field-grid">
          <Field label="City (optional)"><input value={city} onChange={(event) => setCity(event.target.value)} maxLength={160} disabled={!!reserved} placeholder="Brooklyn, NY" /></Field>
          <Field label="Starting configuration"><select value={template} onChange={(event) => setTemplate(event.target.value)} disabled={!!reserved} required>
            {templates.map((item) => <option key={item}>{item}</option>)}
          </select></Field>
        </div>}
      </>}
    </fieldset>
    <div className="movie-destination"><Building2 size={17} /><p>{deferred
      ? "Saved as a new venue that needs setup. Assign its show and configuration later."
      : <>Added to <strong>{resumeRecord?.show || show}</strong> with its movie and processed splat.</>}</p></div>
    {busy && <div className="movie-transfer" role="status">
      <div><strong>{progress === 100 ? "Saving movie…" : `Uploading movie · ${progress}%`}</strong><span>Keep this page open until the movie is saved.</span></div>
      <progress aria-label="Movie upload progress" max="100" value={progress} />
    </div>}
    {error && <p className="movie-error" role="alert">{error}</p>}
    <div className="movie-form-actions">
      {busy ? <Button onClick={() => controller.current?.abort()}>Cancel upload</Button>
        : <Button primary type="submit" disabled={!file || uploadingElsewhere || !!library.error || library.loading}>
          <Upload size={16} />{reserved ? "Retry upload" : "Upload & process movie"}
        </Button>}
      <small>After upload, processing continues even when you close this page.</small>
    </div>
  </form>;
}

export function VenueMovieLibrary({ library, show, query, onOpen }) {
  const records = library.venues.filter((record) => (!record.show || record.show === show)
    && record.name.toLowerCase().includes(query.toLowerCase()));
  const pending = records.filter((record) => record.setupStatus === "needs_setup");
  const assigned = records.filter((record) => record.setupStatus === "configured");
  const section = (title, items, subtitle) => <Panel title={title} subtitle={subtitle}>
    {items.length ? <div className="movie-library-list">{items.map((record) => <button
      className="movie-library-row" key={record.id} onClick={() => onOpen(record)}>
      <span className="movie-row-icon"><Film size={23} /></span>
      <span className="movie-row-copy"><strong>{record.name}</strong><small>{record.filename} · {formatBytes(record.size)}</small></span>
      <span className="movie-row-state"><Badge tone={record.status === "failed" ? "amber" : record.status === "ready" ? "green" : "neutral"}>{processingLabel(record)}</Badge>
        <small>{record.setupStatus === "needs_setup" ? "Needs setup" : record.template}</small></span><ArrowRight size={17} />
    </button>)}</div> : <p className="panel-copy">{library.loading ? "Loading venue movies…" : query ? "No matching movies." : "No movies here yet."}</p>}
  </Panel>;
  return <section className="movie-library" aria-label="Uploaded venues">
    <IntakeConnection library={library} />
    {section("Venue inbox", pending, "Movies uploaded for import or setup later. Shared across shows.")}
    {!!assigned.length && section("Movies for this show", assigned, "Source movies, processing progress and venue splats.")}
    <a className="text-link" href="/upload"><Upload size={15} /> Open standalone movie upload <ArrowRight size={15} /></a>
  </section>;
}

export function VenueMovieDetail({ record, library, shows = [], templates = [], currentShow = "", standalone = false, onOpen }) {
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  async function retry() {
    setBusy(true); setError("");
    try { await venueRequest(`/${record.id}/retry`, { method: "POST", body: "{}" }); library.refresh(); }
    catch (failure) { setError(failure.message); }
    finally { setBusy(false); }
  }
  async function setup(event) {
    event.preventDefault(); setBusy(true); setError("");
    const details = Object.fromEntries(new FormData(event.currentTarget));
    try {
      const saved = await venueRequest(`/${record.id}/setup`, { method: "POST", body: JSON.stringify(details) });
      library.refresh(); onOpen?.(saved);
    } catch (failure) { setError(failure.message); }
    finally { setBusy(false); }
  }
  return <div className="movie-detail">
    <IntakeConnection library={library} />
    <Panel title={record.name} subtitle={`${record.filename} · ${formatBytes(record.size)}`} action={<Badge tone={record.setupStatus === "needs_setup" ? "amber" : "green"}>{record.setupStatus === "needs_setup" ? "Needs setup" : "Added to show"}</Badge>}>
      <div className="movie-job-status" role="status">
        {record.status === "ready" ? <CheckCircle2 size={28} /> : <Film size={28} />}
        <div><h2>{processingLabel(record)}</h2><p>{record.status === "ready"
          ? record.setupStatus === "needs_setup" ? "Your movie has been processed. This venue is saved in the inbox for setup later." : "Your venue and its processed splat are saved. Review the room before adapting your rig."
          : record.status === "failed" ? record.error
            : record.status === "queued" ? "Your movie is saved. Processing starts when the current job finishes."
              : record.status === "awaiting_upload" ? "The movie has not been saved yet. Resume its upload below."
                : record.status === "uploading" ? "A movie upload is in progress. Its status will update here."
                  : "Movie2Splat is building your venue. You can leave this page and return later."}</p>
          {record.frames > 0 && <small>{record.frames} extracted frames{record.registered > 0 ? ` · ${record.registered} registered` : ""}</small>}
        </div>
      </div>
      <div className="movie-record-meta">
        <span>Saved {new Date(record.createdAt).toLocaleString()}</span>
        {record.show && <span>{record.show} · {record.template}</span>}
        {record.city && <span>{record.city}</span>}
      </div>
      <div className="movie-links">
        {record.assetUrl && <a className="button primary" href={record.assetUrl} download>Download venue splat</a>}
        {record.logUrl && <a className="button" href={record.logUrl} download>Processing log</a>}
        {record.status === "failed" && <Button primary onClick={retry} disabled={busy || !!library.error}>{busy ? "Queuing…" : "Retry processing"}</Button>}
      </div>
    </Panel>
    {error && <p role="alert" className="movie-error">{error}</p>}
    {["awaiting_upload", "uploading"].includes(record.status) && <Panel title="Finish uploading this movie">
      <MovieUploadForm library={library} resumeRecord={record} onQueued={() => library.refresh()} />
    </Panel>}
    {record.setupStatus === "needs_setup" && (standalone
      ? <a className="button" href={`/?screen=venue-detail&venueId=${record.id}`}>Open venue setup <ArrowRight size={16} /></a>
      : <Panel title="Set up this venue" subtitle="Name the room and choose where it belongs. The original movie and splat stay linked to this venue.">
        {record.status !== "ready" && <p className="panel-copy">Setup becomes available when processing is complete.</p>}
        <form className="movie-setup-form" onSubmit={setup}>
          <fieldset disabled={record.status !== "ready" || busy || !!library.error}>
            <Field label="Venue name"><input name="name" defaultValue={record.name} required maxLength={160} /></Field>
            <Field label="City (optional)"><input name="city" defaultValue={record.city} maxLength={160} /></Field>
            <div className="field-grid">
              <Field label="Show"><select name="show" defaultValue={currentShow || shows[0]} required>{shows.map((show) => <option key={show}>{show}</option>)}</select></Field>
              <Field label="Starting configuration"><select name="template" defaultValue={templates[0]} required>{templates.map((template) => <option key={template}>{template}</option>)}</select></Field>
            </div>
            <Button type="submit" primary>{busy ? "Saving…" : "Import venue into show"}<ArrowRight size={15} /></Button>
          </fieldset>
        </form>
      </Panel>)}
  </div>;
}

export function StandaloneMovieUpload() {
  const library = useVenueLibrary();
  const [id, setId] = useState(new URLSearchParams(location.search).get("venue"));
  const record = library.venues.find((item) => item.id === id);
  useEffect(() => { document.title = "Upload a venue movie · Venue Volume"; }, []);
  function queued(item) {
    history.replaceState({}, "", `/upload?venue=${item.id}`);
    setId(item.id); library.refresh();
  }
  return <div className="standalone-movie">
    <header className="movie-site-header"><a className="movie-brand" href="/?screen=venues">venue <b>volume</b><span>/ CAPTURE</span></a><a className="text-link" href="/?screen=venues">Venue workspace <ArrowRight size={15} /></a></header>
    <main>
      <div className="movie-intro"><span className="eyebrow">ONE MOVIE. A NEW VENUE.</span><h1>Capture now.<br />Make it a venue later.</h1><p>Upload a walkthrough of your room. We’ll process the movie into a 3D splat and save a new venue for you to set up when you’re ready.</p></div>
      {id ? <>
        <Button onClick={() => { history.replaceState({}, "", "/upload"); setId(null); }}><ArrowLeft size={15} /> Upload another movie</Button>
        {record ? <VenueMovieDetail key={record.id} record={record} library={library} standalone />
          : <><IntakeConnection library={library} /><p role="status">{library.loading ? "Loading your venue…" : library.error ? "Reconnect to load your saved venue." : "This venue could not be found. Check the link or upload another movie."}</p></>}
      </> : <div className="movie-upload-layout">
        <Panel title="Upload your movie" subtitle="No show or configuration needed."><MovieUploadForm library={library} onReserved={(item) => history.replaceState({}, "", `/upload?venue=${item.id}`)} onQueued={queued} /></Panel>
        <aside className="movie-guide">
          <span className="eyebrow">FROM CAMERA TO ROOM</span>
          <ol><li><span>01</span><div><h2>Walk the room</h2><p>Move slowly through a static space. Keep views overlapping and exposure steady.</p></div></li>
            <li><span>02</span><div><h2>Upload & process</h2><p>Movie2Splat reconstructs the room and creates a 3D Gaussian splat. Processing may take a while.</p></div></li>
            <li><span>03</span><div><h2>Set up when ready</h2><p>Your venue waits in the inbox. Add its details and assign a show later.</p></div></li></ol>
          <p className="movie-guide-note">For a reliable capture, use your phone’s standard camera mode and avoid moving people, mirrors and sudden turns.</p>
        </aside>
      </div>}
    </main>
    <footer>VENUE VOLUME <span>/</span> ROOM FOR YOUR NEXT SHOW.</footer>
  </div>;
}
