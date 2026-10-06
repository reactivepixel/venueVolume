import React, {useState} from 'react';
import {makeSnapshot} from './live-model';
import {Field, Panel} from './components';

export default function CuePaletteAssignments({data, venue, onChange}) {
  const snapshot=makeSnapshot(data,venue);
  const [entryId, select]=useState(snapshot.script[1]?.entryId ?? snapshot.script[0]?.entryId);
  const entry=snapshot.script.find(e=>e.entryId===entryId) ?? snapshot.script[0];
  const roles=[...new Set(data.fixtures.map(f=>f.role))];
  const toggle=(role,name,enabled)=>{
    const assignments=[...(entry.assignments ?? [])];
    const index=assignments.findIndex(a=>a.role===role);
    const original=index>=0 ? assignments[index] : {role};
    const names=original.paletteNames ?? (original.preset ? [original.preset] : []);
    const paletteNames=enabled ? [...names.filter(n=>n!==name),name] : names.filter(n=>n!==name);
    const next={...original,paletteNames,preset:paletteNames.at(-1)};
    if(index>=0) assignments[index]=next; else assignments.push(next);
    onChange(data.script.map(e=>e.entryId===entry.entryId ? {...e,assignments} : e));
  };
  return <Panel title="Fixture palette assignments" subtitle="Combine intensity, color and position palettes. Later assignments win for overlapping attributes.">
    <Field label="Cue to edit"><select value={entry?.entryId ?? ''} onChange={e=>select(e.target.value)}>{snapshot.script.map(e=><option key={e.entryId} value={e.entryId}>{e.name}</option>)}</select></Field>
    {roles.map(role=>{
      const assignment=entry?.assignments.find(a=>a.role===role);
      const names=assignment?.paletteNames ?? (assignment?.preset ? [assignment.preset] : []);
      return <fieldset key={role}><legend>{role}</legend><div style={{maxHeight:240,overflowY:'auto',display:'grid',gap:8}}>{data.presets.map(p=><label key={p.name}><input type="checkbox" aria-label={`${role}: ${p.name}`} checked={names.includes(p.name)} onChange={e=>toggle(role,p.name,e.target.checked)}/>{p.name} {p.phaser ? '· Phaser' : '· Palette'}</label>)}</div></fieldset>;
    })}
  </Panel>;
}
