import React, { useEffect, useRef, useState } from "react";
import { ArrowDown, ArrowUp, GripVertical, X } from "lucide-react";
import { moveScriptEntry, normalizeScript } from "./model";
import "./script-slots.css";

export default function ScriptSlots({ entries, onChange }) {
  const listRef = useRef(null);
  const dragRef = useRef(null);
  const frameRef = useRef(null);
  const [drag, setDrag] = useState(null);
  const [announcement, setAnnouncement] = useState("");
  const rows = normalizeScript(entries);

  function cancel() {
    cancelAnimationFrame(frameRef.current);
    dragRef.current = null;
    setDrag(null);
  }
  useEffect(() => {
    // Cancel stale drags if another editor updates the script.
    cancel();
    return () => cancelAnimationFrame(frameRef.current);
  }, [entries]);

  function move(sourceId, targetId) {
    const source = rows.find((entry) => entry.entryId === sourceId);
    const index = rows.findIndex((entry) => entry.entryId === targetId);
    if (!source || index < 0 || sourceId === targetId) return;
    onChange((current) => moveScriptEntry(current, sourceId, targetId));
    setAnnouncement(`${source.name} moved to slot ${index + 1}.`);
  }
  function track() {
    const current = dragRef.current;
    const list = listRef.current;
    if (!current || !list) return;
    if (current.active) {
      const bounds = list.getBoundingClientRect();
      const inside = current.x >= bounds.left && current.x <= bounds.right && current.y >= bounds.top && current.y <= bounds.bottom;
      if (inside) {
        if (current.y < bounds.top + 40) list.scrollTop -= 9;
        if (current.y > bounds.bottom - 40) list.scrollTop += 9;
      }
      const hit = document.elementFromPoint(current.x, current.y)?.closest("[data-script-entry]");
      const targetId = inside && list.contains(hit) ? hit.dataset.scriptEntry : null;
      if (targetId !== current.targetId) current.targetId = targetId;
      setDrag((old) => old?.targetId === targetId && old?.sourceId === current.sourceId ? old : { sourceId: current.sourceId, targetId });
    }
    frameRef.current = requestAnimationFrame(track);
  }
  function start(event, entryId) {
    if (event.button !== 0 || !event.isPrimary) return;
    event.currentTarget.setPointerCapture(event.pointerId);
    dragRef.current = { sourceId: entryId, targetId: null, x: event.clientX, y: event.clientY, startY: event.clientY, active: false };
    frameRef.current = requestAnimationFrame(track);
  }
  function finish(event) {
    const current = dragRef.current;
    const list = listRef.current;
    const bounds = list?.getBoundingClientRect();
    const hit = document.elementFromPoint(event.clientX, event.clientY)?.closest("[data-script-entry]");
    const inside = bounds && event.clientX >= bounds.left && event.clientX <= bounds.right && event.clientY >= bounds.top && event.clientY <= bounds.bottom;
    if (current?.active && inside && list.contains(hit)) move(current.sourceId, hit.dataset.scriptEntry);
    cancel();
  }
  function edit(entryId, patch) {
    onChange((current) => normalizeScript(current).map((entry) => entry.entryId === entryId ? { ...entry, ...patch } : entry));
  }
  return (
    <div className="script-slot-editor" onKeyDown={(event) => {
      if (event.key === "Escape") { cancel(); setAnnouncement("Reorder cancelled."); }
    }}>
      <p id="script-drag-help" className="slot-instructions">Drag a grip into a numbered slot. Use ↑ / ↓ on a focused grip or the move buttons. Escape cancels. Live playback changes require review.</p>
      <div className="slot-announcement" role="status" aria-live="polite">{announcement || (drag ? "Drop onto a slot to move this cue." : `${rows.length} cue slots · edit draft`)}</div>
      <ol className="script-slots" aria-label="Script cue slots" ref={listRef}>
        {rows.map((entry, index) => (
          <li key={entry.entryId} data-script-entry={entry.entryId}
            className={`script-slot ${drag?.sourceId === entry.entryId ? "drag-source" : ""} ${drag?.targetId === entry.entryId ? "drop-target" : ""}`}>
            <div className="slot-identity">
              <span className="slot-number" aria-label={`Slot ${index + 1}`}>{String(index + 1).padStart(2, "0")}</span>
              <button type="button" className="slot-grip" aria-label={`Reorder slot ${index + 1}: ${entry.name}`} aria-describedby="script-drag-help"
                onPointerDown={(event) => start(event, entry.entryId)}
                onPointerMove={(event) => {
                  const current = dragRef.current;
                  if (!current) return;
                  current.x = event.clientX; current.y = event.clientY;
                  if (Math.abs(current.y - current.startY) > 6) current.active = true;
                }}
                onPointerUp={finish} onPointerCancel={cancel} onLostPointerCapture={cancel}
                onKeyDown={(event) => {
                  if (event.key !== "ArrowUp" && event.key !== "ArrowDown") return;
                  event.preventDefault();
                  const target = rows[index + (event.key === "ArrowUp" ? -1 : 1)];
                  if (target) move(entry.entryId, target.entryId);
                }}><GripVertical size={19} /></button>
            </div>
            <div className="slot-cue">
              <small>{entry.id} · cue reference</small><strong>{entry.name}</strong>
              <span>{entry.operatorNote}</span>
            </div>
            <div className="slot-timing">
              <label>Song / segment<input aria-label={`${entry.id} song`} value={entry.song} onChange={(event) => edit(entry.entryId, { song: event.target.value })} /></label>
              <label>Offset (s)<input aria-label={`${entry.id} offset seconds`} type="number" min="0" value={entry.offset} onChange={(event) => edit(entry.entryId, { offset: Math.max(0, Number(event.target.value)) })} /></label>
            </div>
            <div className="slot-actions">
              <button type="button" aria-label={`Move ${entry.name} up`} disabled={index === 0} onClick={() => move(entry.entryId, rows[index - 1]?.entryId)}><ArrowUp size={16} /></button>
              <button type="button" aria-label={`Move ${entry.name} down`} disabled={index === rows.length - 1} onClick={() => move(entry.entryId, rows[index + 1]?.entryId)}><ArrowDown size={16} /></button>
              <button type="button" aria-label={`Remove ${entry.name} from script`} disabled={rows.length === 1} onClick={() => onChange((current) => normalizeScript(current).filter((item) => item.entryId !== entry.entryId))}><X size={16} /></button>
            </div>
          </li>
        ))}
      </ol>
    </div>
  );
}
