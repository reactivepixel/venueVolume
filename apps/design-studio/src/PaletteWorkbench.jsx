import React, { useEffect, useState } from 'react';
import { baselinePalettes, samplePhaser, validPhaser } from './palettes-phasers';
import { Button, Field, Panel } from './components';

export default function PaletteWorkbench({ palettes, onSave }) {
  const [selected, select] = useState(palettes[0]?.name);
  const [draft, edit] = useState(() => structuredClone(palettes[0] ?? baselinePalettes[0]));
  const [seconds, clock] = useState(0);
  const [notice, notify] = useState('');
  useEffect(() => { const start = performance.now(); const id = setInterval(() => clock((performance.now() - start) / 1000), 33); return () => clearInterval(id); }, []);
  const update = patch => edit(d => ({ ...d, ...patch }));
  const updatePhaser = patch => update({ phaser: { ...draft.phaser, ...patch } });
  const sample = samplePhaser(draft, seconds);
  const choose = name => { const p = palettes.find(p => p.name === name); if (p) { select(name); const copy = structuredClone(p); if (copy.phaser && !validPhaser(copy.phaser)) { copy.phaser = undefined; notify("Invalid phaser loaded as a static palette. Fix it before saving."); } else notify(''); edit(copy); } };
  const save = async () => {
    const name = draft.name.trim();
    if (!name || palettes.some(p => p.name === name && p.name !== selected)) { notify('Choose a unique palette name.'); return; }
    if (draft.phaser && !validPhaser(draft.phaser)) { notify("Check phaser step values, widths, speed and measure."); return; }
    await onSave({ ...draft, name }, selected); select(name); notify('Saved palette and phaser values.');
  };
  return <Panel title="Palette & phaser workbench" subtitle="Static attribute palettes and reusable cyclic effects · simulation only">
    <div className="form-fields">
      <Field label="Library"><select aria-label="Palette library" value={selected ?? ''} onChange={e => choose(e.target.value)}>{palettes.map(p => <option key={p.name}>{p.name}</option>)}</select></Field>
      <div className="row-actions"><Button onClick={() => { select(undefined); edit({ ...structuredClone(draft), name: `${draft.name} copy`, count: 0 }); }}>Duplicate and customize</Button><Button onClick={() => { select(undefined); edit(structuredClone(baselinePalettes[0])); update({name: 'New palette'}); }}>New palette</Button></div>
      <Field label="Palette name"><input value={draft.name} onChange={e => update({ name: e.target.value })}/></Field>
      <div aria-label="Live palette simulation" style={{ height: 210, background: '#fff', position: 'relative', overflow: 'hidden', borderRadius: 12, backgroundImage: 'linear-gradient(#ccd2d9 1px, transparent 1px), linear-gradient(90deg, #ccd2d9 1px, transparent 1px)', backgroundSize: '24px 24px' }}>
        <div style={{ position: 'absolute', left: `calc(50% + ${sample.pan}px)`, top: `calc(50% + ${sample.tilt}px)`, width: 48, height: 48, background: sample.color, opacity: Math.max(0.05, sample.intensity / 100), boxShadow: `0 0 65px 35px ${sample.color}`, transform: 'rotate(-20deg) skewY(10deg)' }}/>
      </div>
      <p className="panel-note">Live output: {sample.intensity.toFixed(0)}% · {sample.color} · pan {sample.pan.toFixed(0)}° · tilt {sample.tilt.toFixed(0)}°</p>
      <Field label="Included attributes"><div className="check-row">{['intensity','color','pan','tilt'].map(key => <label key={key}><input type="checkbox" checked={(draft.attributes ?? ['intensity','color']).includes(key)} onChange={e => update({ attributes: e.target.checked ? [...(draft.attributes ?? ['intensity','color']), key] : (draft.attributes ?? ['intensity','color']).filter(k => k !== key) })}/>{key} </label>)}</div></Field>
      <Field label="Intensity"><input type="range" min="0" max="100" value={draft.intensity} onChange={e => update({ intensity: +e.target.value })}/></Field>
      <Field label="Color"><input type="color" value={draft.color} onChange={e => update({ color: e.target.value })}/></Field>
      {['pan','tilt'].map(key => <Field key={key} label={key}><input type="number" min="-180" max="180" value={draft[key] ?? 0} onChange={e => update({ [key]: +e.target.value })}/></Field>)}
      <label><input type="checkbox" checked={!!draft.phaser} onChange={e => update({ phaser: e.target.checked ? { bpm: 60, measure: 1, phase: 0, spread: 0, transition: 1, steps: [{ intensity: draft.intensity, color: draft.color, width: 1 }, { intensity: 0, color: draft.color, width: 1 }] } : undefined })}/> Animate as phaser</label>
      {draft.phaser && <>
        {[['bpm','Speed (BPM)',1,240],['measure','Measure (beats)',0.25,64],['phase','Phase (degrees)',0,360],['spread','Fixture phase spread',0,360],['transition','Transition',0,1]].map(([key,label,min,max]) => <Field key={key} label={label}><input type="number" min={min} max={max} step={key === 'transition' ? 0.05 : 0.25} value={draft.phaser[key]} onChange={e => updatePhaser({[key]: Math.min(max, Math.max(min, +e.target.value))})}/></Field>)}
        {draft.phaser.steps.map((step,index) => <fieldset key={index}><legend>Step {index+1}</legend>{[['intensity',0,100],['pan',-180,180],['tilt',-180,180],['width',0.1,8]].map(([key,min,max]) => <Field key={key} label={key}><input type="number" min={min} max={max} step={0.1} value={step[key] ?? (key === 'width' ? 1 : draft[key] ?? 0)} onChange={e => updatePhaser({ steps: draft.phaser.steps.map((s,i) => i === index ? {...s,[key]: Math.min(max, Math.max(min,+e.target.value))} : s) })}/></Field>)}<Field label="Step color"><input type="color" value={step.color ?? draft.color} onChange={e => updatePhaser({steps: draft.phaser.steps.map((s,i) => i === index ? {...s,color:e.target.value} : s)})}/></Field><Button disabled={draft.phaser.steps.length <= 2} onClick={() => updatePhaser({steps:draft.phaser.steps.filter((_,i) => i !== index)})}>Remove step</Button></fieldset>)}
        <Button disabled={draft.phaser.steps.length >= 32} onClick={() => updatePhaser({steps:[...draft.phaser.steps, structuredClone(draft.phaser.steps.at(-1))]})}>Add step</Button>
      </>}
      <Button primary onClick={save}>Save palette / phaser</Button><p role="status">{notice}</p>
    </div>
  </Panel>;
}
