import React, { useState } from "react";
import {
  Check,
  Crosshair,
  Lightbulb,
  Minus,
  Plus,
  RotateCcw,
} from "lucide-react";
import { fixtureRows, presetRows } from "./catalog";

export function SelectionInspector({
  fixtures,
  ids,
  values,
  onChange,
  onRelease,
  presets = presetRows,
  live = false,
}) {
  const selected = fixtures.filter((f) => ids.includes(f.id));
  const levels = selected.map((f) => values[f.id]?.intensity ?? 0);
  const mixed = levels.some((n) => n !== levels[0]);
  const intensity = levels[0] ?? 0;
  const moving =
    selected.length > 0 && selected.every((f) => /Profile|Beam/.test(f.model));
  return (
    <section
      className="selection-inspector"
      aria-label="Selected fixture controls"
    >
      <div className="selection-heading">
        <span>
          <Crosshair size={15} />
          SELECTED
        </span>
        <b data-testid="selection-count">
          {selected.length} / {fixtures.length}
        </b>
      </div>
      <h3>
        {selected.length === fixtures.length
          ? "Whole venue"
          : selected.length === 1
            ? selected[0].name
            : selected.length
              ? `${selected.length} fixtures`
              : "Select fixtures on stage"}
      </h3>
      <p>
        {selected.length
          ? [...new Set(selected.map((f) => f.role))].join(" · ")
          : "Tap a fixture or select a group. Selection never fires a cue."}
      </p>
      <fieldset disabled={!selected.length}>
        <div className="parameter-readout">
          <label htmlFor={live ? "live-intensity" : "preview-intensity"}>
            Intensity
          </label>
          <strong>{mixed ? "Mixed" : `${intensity}%`}</strong>
        </div>
        <input
          id={live ? "live-intensity" : "preview-intensity"}
          aria-label="Selected intensity"
          type="range"
          min="0"
          max="100"
          value={intensity}
          onChange={(e) => onChange({ intensity: Number(e.target.value) })}
        />
        <div className="nudge-row">
          <button onClick={() => onChange(null, -5)}>
            <Minus size={14} />
            5%
          </button>
          <button onClick={() => onChange({ intensity: 0 })}>0</button>
          <button onClick={() => onChange({ intensity: 50 })}>50</button>
          <button onClick={() => onChange({ intensity: 100 })}>Full</button>
          <button onClick={() => onChange(null, 5)}>
            <Plus size={14} />
            5%
          </button>
        </div>
        <div className="parameter-readout">
          <label>Color</label>
          <input
            type="color"
            aria-label="Selected color"
            value={values[selected[0]?.id]?.color || "#7386ee"}
            onChange={(e) => onChange({ color: e.target.value })}
          />
        </div>
        <div className="live-color-palette">
          {[
            "#f2dfb1",
            "#eaaa72",
            "#e67896",
            "#b594f2",
            "#7386ee",
            "#5ecbc0",
            "#fafaff",
          ].map((color) => (
            <button
              key={color}
              aria-label={`Set color ${color}`}
              style={{ "--swatch": color }}
              onClick={() => onChange({ color })}
            />
          ))}
        </div>
        <label className="select-preset">
          Apply preset
          <select
            aria-label="Apply selected preset"
            value=""
            onChange={(e) => {
              const preset = presets.find((p) => p.name === e.target.value);
              if (preset)
                onChange({ intensity: preset.intensity, color: preset.color });
            }}
          >
            <option value="" disabled>
              Choose a look…
            </option>
            {presets.map((p) => (
              <option key={p.name}>{p.name}</option>
            ))}
          </select>
        </label>
        <div className="position-controls">
          <label>
            Pan
            <input
              aria-label="Selected pan"
              type="range"
              min="0"
              max="100"
              disabled={!moving}
              value={values[selected[0]?.id]?.pan ?? 50}
              onChange={(e) => onChange({ pan: Number(e.target.value) })}
            />
          </label>
          <label>
            Tilt
            <input
              aria-label="Selected tilt"
              type="range"
              min="0"
              max="100"
              disabled={!moving}
              value={values[selected[0]?.id]?.tilt ?? 50}
              onChange={(e) => onChange({ tilt: Number(e.target.value) })}
            />
          </label>
        </div>
        {!moving && (
          <small>Pan/tilt requires a selection of moving fixtures.</small>
        )}
        <button className="release-selection" onClick={onRelease}>
          <RotateCcw size={14} />
          {live ? "Release selected to cue" : "Reset preview"}
        </button>
      </fieldset>
      <p className="selection-note">
        {live
          ? "Manual values stay through cue calls until released. No presets are overwritten."
          : "Preview controls only · does not change a show or send output."}
      </p>
    </section>
  );
}

export function RigSurface({
  fixtures = fixtureRows,
  ids,
  onSelect,
  values = {},
  compact = false,
}) {
  const roles = [...new Set(fixtures.map((f) => f.role))];
  const positions = [
    [18, 20],
    [39, 20],
    [61, 20],
    [82, 20],
    [24, 79],
    [76, 79],
    [10, 51],
    [90, 51],
  ];
  return (
    <div className={`rig-surface ${compact ? "compact-rig" : ""}`}>
      <div className="rig-toolbar">
        <span>
          <Lightbulb size={15} />
          STAGE / TOP VIEW
        </span>
        <span>Tap to toggle selection</span>
      </div>
      <div className="rig-group-buttons">
        <button
          aria-pressed={ids.length === fixtures.length}
          onClick={() => onSelect(fixtures.map((f) => f.id))}
        >
          Whole venue
        </button>
        {roles.map((role) => (
          <button
            key={role}
            aria-pressed={fixtures
              .filter((f) => f.role === role)
              .every((f) => ids.includes(f.id))}
            onClick={() =>
              onSelect(fixtures.filter((f) => f.role === role).map((f) => f.id))
            }
          >
            {role}
          </button>
        ))}
        <button onClick={() => onSelect([])}>Clear selection</button>
      </div>
      <div className="rig-canvas" aria-label="Interactive stage">
        <div className="rig-boundary" />
        <span className="rig-dimension">MAIN STAGE · 12 × 8 m</span>
        <div className="rig-drum">DRUM RISER</div>
        <span className="rig-keys">KEYS</span>
        <span className="rig-guitar">GUITAR</span>
        <span className="rig-vocal">VOCAL</span>
        <span className="rig-audience">DOWNSTAGE / AUDIENCE</span>
        {fixtures.map((f, i) => {
          const [x, y] = positions[i] || [
            15 + (i % 5) * 17,
            40 + Math.floor((i - 8) / 5) * 13,
          ];
          const v = values[f.id];
          return (
            <button
              key={f.id}
              className={`rig-fixture ${ids.includes(f.id) ? "selected" : ""} ${v?.manual ? "manual" : ""}`}
              aria-label={`Select ${f.name}`}
              aria-pressed={ids.includes(f.id)}
              style={{
                left: `${x}%`,
                top: `${y}%`,
                "--fixture-color": v?.color || "#849bd4",
              }}
              onClick={() =>
                onSelect(
                  ids.includes(f.id)
                    ? ids.filter((id) => id !== f.id)
                    : [...ids, f.id],
                )
              }
            >
              <Lightbulb size={19} />
              <span>{f.id.replace("FX-", "")}</span>
              <small>
                {v?.unknown
                  ? "Unknown"
                  : `${v?.effective ?? v?.intensity ?? 0}%`}
              </small>
              {ids.includes(f.id) && (
                <Check className="fixture-check" size={12} />
              )}
            </button>
          );
        })}
      </div>
      <div className="rig-caption">
        <span>
          {fixtures.length} fixtures · {ids.length} selected
        </span>
        <span>Ring = selected · amber marker = manual</span>
      </div>
    </div>
  );
}

export function StagePreview({
  fixtures = fixtureRows,
  onSelect,
  look = "#7386ee",
  large = false,
}) {
  const [ids, setIds] = useState([]),
    [values, setValues] = useState({});
  const rendered = Object.fromEntries(
    fixtures.map((f) => [
      f.id,
      { intensity: 75, color: look, ...values[f.id] },
    ]),
  );
  function change(next, nudge) {
    setValues((old) => ({
      ...old,
      ...Object.fromEntries(
        ids.map((id) => [
          id,
          {
            ...rendered[id],
            ...(next || {
              intensity: Math.max(
                0,
                Math.min(100, rendered[id].intensity + nudge),
              ),
            }),
          },
        ]),
      ),
    }));
  }
  return (
    <div className={`stage-preview ${large ? "large" : ""}`}>
      <RigSurface
        compact={!large}
        fixtures={fixtures}
        ids={ids}
        onSelect={(next) => {
          setIds(next);
          if (onSelect && next.length)
            onSelect(fixtures.findIndex((f) => f.id === next.at(-1)));
        }}
        values={rendered}
      />
      {ids.length > 0 && (
        <SelectionInspector
          fixtures={fixtures}
          ids={ids}
          values={rendered}
          onChange={change}
          onRelease={() =>
            setValues((old) =>
              Object.fromEntries(
                Object.entries(old).filter(([id]) => !ids.includes(id)),
              ),
            )
          }
        />
      )}
    </div>
  );
}
