import React, { useEffect, useState } from 'react';
import { attributesOf, createPalette, createPhaser, paletteIssue, palettePools, poolAttributes, poolOf, samplePhaser } from './palettes-phasers';
import { Button, Field } from './components';
import './palettes.css';

const attributeLabels = {intensity: 'Dimmer', color: 'Color', pan: 'Pan', tilt: 'Tilt'};
export default function PaletteWorkbench({ palettes, fixtures = [], script = [], onSave, onApply }) {
  const initial = palettes[0] ?? createPalette();
  const [selected, select] = useState(initial.name);
  const [draft, edit] = useState(() => structuredClone(initial));
  const [saved, remember] = useState(() => JSON.stringify(initial));
  const [pool, setPool] = useState('All pools');
  const [query, search] = useState('');
  const [kind, setKind] = useState('All');
  const [stepIndex, selectStep] = useState(0);
  const [ids, setIds] = useState([]);
  const [entryId, setEntry] = useState(script[0]?.entryId ?? '');
  const [seconds, clock] = useState(0);
  const [playing, play] = useState(() => !window.matchMedia('(prefers-reduced-motion: reduce)').matches);
  const [notice, notify] = useState('');
  const [busy, setBusy] = useState(false);
  const [pending, setPending] = useState(null);
  const dirty = JSON.stringify(draft) !== saved;
  const issue = paletteIssue(draft, palettes);
  const currentIds = ids.filter(id => fixtures.some(f => f.id === id));
  const targetEntry = script.find(e => e.entryId === entryId);
  const filtered = palettes.filter(p => (pool === 'All pools' || poolOf(p) === pool) && (kind === 'All' || !!p.phaser === (kind === 'Phasers')) && p.name.toLowerCase().includes(query.toLowerCase()));
  const currentStep = draft.phaser?.steps[Math.min(stepIndex, draft.phaser.steps.length - 1)];
  const usedBy = script.filter(e => e.preset === selected || e.assignments?.some(a => a.preset === selected || a.paletteNames?.includes(selected))).length;
  const dependencies = palettes.filter(p => p.phaser?.steps.some(s => s.paletteName === selected)).length;
  useEffect(() => { if (!playing) return; const start = performance.now() - seconds * 1000; const id = setInterval(() => clock((performance.now() - start) / 1000), 50); return () => clearInterval(id); }, [playing]);
  const update = patch => edit(d => ({...d, ...patch}));
  const updatePhaser = patch => edit(d => ({...d, phaser: {...d.phaser, ...patch}}));
  const updateStep = patch => updatePhaser({steps: draft.phaser.steps.map((s,i) => i === stepIndex ? {...s, ...patch} : s)});
  const load = palette => { select(palette.name); edit(structuredClone(palette)); remember(JSON.stringify(palette)); selectStep(0); notify(''); };
  const navigate = action => { if (dirty) setPending({action}); else action(); };
  const save = async () => {
    if (busy) return false;
    if (issue) { notify(issue); return false; }
    const name = draft.name.trim();
    if (palettes.some(p => p.name === name && p.name !== selected)) { notify('Choose a unique palette name.'); return false; }
    setBusy(true);
    try { const palette = {...draft, name, type: poolOf(draft)}; await onSave(palette, selected); select(name); remember(JSON.stringify(palette)); edit(current => JSON.stringify(current) === JSON.stringify(draft) ? palette : current); notify(selected ? 'Updated palette and its references.' : 'Stored new palette.'); return true; }
    catch (error) { notify(error.message || 'Could not save palette. Your draft is still available.'); return false; }
    finally { setBusy(false); }
  };
  const newPalette = () => { const p = createPalette(pool === 'All pools' ? 'Intensity' : pool); select(undefined); edit(p); remember(''); selectStep(0); notify(''); };
  const duplicate = () => { select(undefined); edit({...structuredClone(draft), name: `${draft.name} copy`, count: 0}); remember(''); notify('Independent copy · store with a new name.'); };
  const apply = async () => {
    if (!currentIds.length || !targetEntry || dirty || !selected || busy) return;
    setBusy(true);
    try { await onApply(draft, currentIds, entryId); notify(`Applied ${draft.name} to ${currentIds.length} fixtures in ${targetEntry.name}.`); }
    catch (error) { notify(error.message || 'Could not apply palette.'); }
    finally { setBusy(false); }
  };
  const valueControl = (key, value, set) => <Field key={key} label={attributeLabels[key]}>
    {key === 'color' ? <div className="palette-color-value"><input aria-label="Color value" type="color" value={value} onChange={e => set(e.target.value)}/><code>{value}</code></div> : <div className="palette-value"><input aria-label={`${attributeLabels[key]} value`} type="range" min={key === 'intensity' ? 0 : -180} max={key === 'intensity' ? 100 : 180} value={value ?? 0} onChange={e => set(+e.target.value)}/><input aria-label={`${attributeLabels[key]} numeric value`} type="number" min={key === 'intensity' ? 0 : -180} max={key === 'intensity' ? 100 : 180} value={value ?? 0} onChange={e => set(+e.target.value)}/><span>{key === 'intensity' ? '%' : '°'}</span></div>}
  </Field>;
  return <section className="palette-console" aria-label="Palette programmer">
      <section className="palette-apply palette-selection-row" aria-label="Apply palette to fixtures">
        <div className="palette-section-heading"><h3>Fixture selection</h3><span>{currentIds.length} selected</span><button onClick={() => setIds([])}>Clear selection</button></div>
        <div className="palette-group-buttons">{[...new Set(fixtures.map(f => f.role))].map(role => <button key={role} aria-pressed={fixtures.filter(f => f.role === role).every(f => currentIds.includes(f.id))} onClick={() => setIds(fixtures.filter(f => f.role === role).map(f => f.id))}>{role}</button>)}</div>
        <details><summary>Choose individual fixtures · {fixtures.length} available</summary><div className="palette-fixture-list">{fixtures.map(f => <label key={f.id}><input type="checkbox" checked={currentIds.includes(f.id)} onChange={e => setIds(e.target.checked ? [...ids,f.id] : ids.filter(id => id !== f.id))}/>{f.name} <span>{f.role}</span></label>)}</div></details>
        {!fixtures.length && <p className="palette-muted">Add fixtures to the loadout before applying a palette.</p>}
        <div className="palette-apply-row"><Field label="Destination cue"><select value={entryId} onChange={e => setEntry(e.target.value)}><option value="" disabled>Choose a cue</option>{script.map(e => <option key={e.entryId} value={e.entryId}>{e.name}</option>)}</select></Field><Button primary onClick={apply} disabled={!onApply || !currentIds.length || !targetEntry || dirty || !selected || !!issue || busy}>Apply to {currentIds.length} selected</Button></div>
        <p className="palette-muted">Stores palette references in the cue. {dirty ? 'Store your changes before applying.' : 'Unselected fixtures keep their current look.'}</p>
      </section>
    <aside className="palette-pools">
      <div className="palette-section-heading"><h2>Preset pools</h2><span>{palettes.length}</span></div>
      <input aria-label="Search palettes" placeholder="Search palettes…" value={query} onChange={e => search(e.target.value)}/>
      <nav className="palette-pool-tabs" aria-label="Attribute pools">{['All pools', ...palettePools].map(name => <button key={name} aria-pressed={pool === name} onClick={() => setPool(name)}>{name}</button>)}</nav>
      <div className="palette-kind-tabs" aria-label="Palette type">{['All','Static','Phasers'].map(name => <button key={name} aria-pressed={kind === name} onClick={() => setKind(name)}>{name}</button>)}</div>
      <div className="palette-pool-grid">{filtered.map(p => <button key={p.name} className="palette-pool-cell" aria-pressed={selected === p.name} onClick={() => navigate(() => load(p))}>
        <span className="palette-cell-meta"><span>{String(palettes.indexOf(p) + 1).padStart(2,'0')} · {poolOf(p)}</span><span>{p.phaser ? '↝' : '●'}</span></span>
        <strong>{p.name.replace(/^(Intensity|Color|Position|All|Phaser) · /,'')}</strong>
        <span className="palette-cell-detail"><i style={{background: attributesOf(p).includes('color') ? p.color : '#b9c9d4'}}/>{p.phaser ? `${p.phaser.steps.length} steps · ${p.phaser.bpm} BPM` : 'Static'}</span>
      </button>)}</div>
      {!filtered.length && <p className="palette-muted">No palettes in this pool.</p>}
      <Button onClick={() => navigate(newPalette)}>New palette</Button>
    </aside>
    <div className="palette-programmer">
      <header className="palette-editor-heading"><div><p className="palette-eyebrow">{poolOf(draft)} / {draft.phaser ? 'Phaser' : 'Static palette'}</p><h2>{selected ? 'Edit palette' : 'Store palette'}</h2></div><span className={dirty ? 'palette-dirty' : 'palette-muted'}>{dirty ? 'Unsaved changes' : 'Stored'}</span></header>
      <div className="palette-top-fields"><Field label="Palette name"><input value={draft.name} onChange={e => update({name: e.target.value})}/></Field><Field label="Store in pool"><select value={poolOf(draft)} onChange={e => { const category = e.target.value; update({type: category, attributes: [...poolAttributes[category]], phaser: draft.phaser ? {...draft.phaser, steps: draft.phaser.steps.map(s => ({width: s.width ?? 1, ...Object.fromEntries(poolAttributes[category].map(k => [k, s[k] ?? draft[k] ?? 0]))}))} : undefined}); selectStep(0); }}>{palettePools.map(name => <option key={name}>{name}</option>)}</select></Field></div>
      <div className="palette-preview" aria-label="Live palette simulation">
        <div className="palette-preview-grid"/>
        <div className="palette-preview-fixtures">{Array.from({length: Math.min(8, currentIds.length || 4)}, (_, index) => {
          const sample = samplePhaser(draft, seconds, index, Math.min(8, currentIds.length || 4), palettes);
          return <div key={index} className="palette-preview-fixture"><div className="palette-preview-beam" style={{'--beam-color': sample.color, opacity: Math.max(0.08, sample.intensity/100), transform: `translateX(${sample.pan/4}px) rotate(${sample.tilt/4}deg)`}}/><span>{index + 1}</span></div>;
        })}</div>
        <div className="palette-preview-caption"><span>{currentIds.length ? `${currentIds.length} selected · preview` : '4 sample fixtures · preview'}</span><button onClick={() => play(!playing)}>{playing ? 'Pause' : 'Play'}</button><button onClick={() => clock(0)}>Restart</button></div>
      </div>
      <div className="palette-mode"><button aria-pressed={!draft.phaser} onClick={() => { update({phaser: undefined}); selectStep(0); }}>Static values</button><button aria-pressed={!!draft.phaser} onClick={() => { if (!draft.phaser) update({phaser: createPhaser(draft)}); }}>Phaser steps</button></div>
      <p className="palette-muted">Owns {attributesOf(draft).map(k => attributeLabels[k]).join(', ')}. Applying preserves other attributes.</p>
      {draft.phaser ? <>
        <div className="palette-step-strip" aria-label="Phaser steps">{draft.phaser.steps.map((step,index) => <button key={index} aria-pressed={stepIndex === index} onClick={() => selectStep(index)}><b>Step {index+1}</b><span>{step.paletteName || 'Custom values'}</span></button>)}<button disabled={draft.phaser.steps.length >= 32} onClick={() => { updatePhaser({steps:[...draft.phaser.steps, structuredClone(draft.phaser.steps.at(-1))]}); selectStep(draft.phaser.steps.length); }}>+ Add step</button></div>
        <div className="palette-step-editor"><div className="palette-top-fields"><Field label="Step source"><select value={currentStep.paletteName ?? ''} onChange={e => updateStep({paletteName:e.target.value || undefined})}><option value="">Custom values</option>{palettes.filter(p => !p.phaser && p.name !== selected && attributesOf(draft).every(a => attributesOf(p).includes(a))).map(p => <option key={p.name}>{p.name}</option>)}</select></Field><Field label="Step width (ratio)"><input type="number" min="0.1" max="64" step="0.1" value={currentStep.width ?? 1} onChange={e => updateStep({width:+e.target.value})}/></Field></div>
          {currentStep.paletteName ? <p className="palette-reference">↳ Linked to {currentStep.paletteName}. Updating that palette updates this step.</p> : <div className="palette-attributes">{attributesOf(draft).map(k => valueControl(k, currentStep[k] ?? draft[k], value => updateStep({[k]:value})))}</div>}
          <Button disabled={draft.phaser.steps.length <= 2} onClick={() => { updatePhaser({steps:draft.phaser.steps.filter((_,i) => i !== stepIndex)}); selectStep(Math.max(0,stepIndex-1)); }}>Remove step</Button>
        </div>
        <div className="palette-timing">{[['bpm','Speed (BPM)',1,600],['measure','Beats per cycle',0.25,64],['phase','Phase offset (°)',-360,360],['spread','Phase spread (°)',-360,360],['transition','Transition',0,1]].map(([key,label,min,max]) => <Field key={key} label={label}><input type="number" min={min} max={max} step={key === 'transition' ? 0.1 : 0.25} value={draft.phaser[key] ?? (key === 'transition' ? 1 : 0)} onChange={e => updatePhaser({[key]:+e.target.value})}/></Field>)}</div>
        <div className="palette-quick"><span>Distribution</span><button onClick={() => updatePhaser({spread:0})}>Together</button><button onClick={() => updatePhaser({spread:360})}>Wave 0–360°</button><button onClick={() => updatePhaser({spread:-360})}>Reverse wave</button><span>{(60*draft.phaser.measure/draft.phaser.bpm).toFixed(2)} s / cycle</span></div>
      </> : <div className="palette-attributes">{attributesOf(draft).map(k => valueControl(k, draft[k], value => update({[k]:value})))}</div>}
      <footer className="palette-store"><span>{usedBy} cue references · {dependencies} linked phasers</span><Button onClick={duplicate} disabled={busy}>Duplicate</Button><Button onClick={() => load(palettes.find(p => p.name === selected) ?? initial)} disabled={!dirty || busy}>Revert</Button><Button primary onClick={save} disabled={busy || !!issue}>{selected ? 'Update palette' : 'Store palette'}</Button></footer>
      {issue && <p className="palette-validation" role="alert">{issue}</p>}
      <p className="palette-status" role="status">{notice}</p>
    </div>
    {pending && <div className="palette-dialog-backdrop"><section role="alertdialog" aria-modal="true" aria-label="Unsaved palette changes" className="palette-dialog"><h2>Unsaved palette changes</h2><p>Store this draft or discard it before switching palettes.</p><div className="row-actions"><Button onClick={() => setPending(null)}>Keep editing</Button><Button onClick={() => { pending.action(); setPending(null); }}>Discard changes</Button><Button primary disabled={busy || !!issue} onClick={async () => { if (await save()) { pending.action(); setPending(null); } }}>Save and continue</Button></div></section></div>}
  </section>;
}
