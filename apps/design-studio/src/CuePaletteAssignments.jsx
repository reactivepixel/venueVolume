import React, {useState} from 'react';
import {makeSnapshot} from './live-model';
import {attributesOf, layeredNames, palettePools, poolOf} from './palettes-phasers';
import {Button, Field, Panel} from './components';

export default function CuePaletteAssignments({data, venue, onChange}) {
  const snapshot=makeSnapshot(data,venue);
  const [entryId, select]=useState(snapshot.script[1]?.entryId ?? snapshot.script[0]?.entryId);
  const [pool, setPool]=useState('Intensity');
  const entry=snapshot.script.find(e=>e.entryId===entryId) ?? snapshot.script[0];
  const roles=[...new Set(data.fixtures.map(f=>f.role))];
  const change=assignments=>onChange(snapshot.script.map(e=>e.entryId===entry.entryId ? {...e,assignments} : e));
  const setRole=(role, palette, remove)=>{
    const assignments=[...(entry.assignments ?? [])];
    const index=assignments.findIndex(a=>!a.fixtureId && a.role===role);
    const original=index>=0 ? assignments[index] : {role};
    const names=original.paletteNames ?? (original.preset ? [original.preset] : []);
    const paletteNames=remove ? names.filter(n=>n!==remove) : layeredNames(names,palette,data.presets);
    const next={...original,paletteNames,preset:paletteNames.at(-1)};
    if(index>=0) assignments[index]=next; else assignments.push(next);
    change(assignments);
  };
  return <Panel title="Cue recipes" subtitle="Group selection + palette references. Fixture overrides take precedence for their attributes.">
    <Field label="Cue to edit"><select value={entry?.entryId ?? ''} onChange={e=>select(e.target.value)}>{snapshot.script.map(e=><option key={e.entryId} value={e.entryId}>{e.name}</option>)}</select></Field>
    {!entry ? <p>Add a cue before assigning palettes.</p> : <>
      <Field label="Attribute pool"><select value={pool} onChange={e=>setPool(e.target.value)}>{palettePools.map(p=><option key={p}>{p}</option>)}</select></Field>
      {roles.map(role=>{
        const assignment=entry.assignments.find(a=>!a.fixtureId && a.role===role);
        const names=assignment?.paletteNames ?? (assignment?.preset ? [assignment.preset] : []);
        return <section key={role} className="cue-recipe-row"><div className="palette-section-heading"><h3>{role}</h3><span>{data.fixtures.filter(f=>f.role===role).length} fixtures</span></div>
          <Field label={`Add ${pool.toLowerCase()} to ${role}`}><select value="" onChange={e=>setRole(role,data.presets.find(p=>p.name===e.target.value))}><option value="" disabled>Choose a palette…</option>{data.presets.filter(p=>poolOf(p)===pool).map(p=><option key={p.name}>{p.name}</option>)}</select></Field>
          <ul className="cue-recipe-values">{names.map(name=>{const palette=data.presets.find(p=>p.name===name); return <li key={name}><div><strong>{name}</strong><small>{palette ? `${attributesOf(palette).join(' · ')}${palette.phaser ? ' · Phaser' : ''}` : 'Missing palette'}</small></div><button aria-label={`Remove ${name} from ${role}`} onClick={()=>setRole(role,null,name)}>×</button></li>;})}</ul>
          {!names.length && <p className="palette-muted">No palette values stored for this group.</p>}
        </section>;
      })}
      {!!entry.assignments.some(a=>a.fixtureId) && <section className="cue-recipe-row"><h3>Fixture overrides</h3>{entry.assignments.filter(a=>a.fixtureId).map(a=><div className="cue-recipe-override" key={a.fixtureId}><div><strong>{data.fixtures.find(f=>f.id===a.fixtureId)?.name ?? 'Missing fixture'}</strong><small>{(a.paletteNames ?? [a.preset]).filter(Boolean).join(' + ')}</small></div><Button onClick={()=>change(entry.assignments.filter(item=>item!==a))}>Use group values</Button></div>)}</section>}
    </>}
  </Panel>;
}
