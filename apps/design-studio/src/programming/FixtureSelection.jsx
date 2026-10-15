import React, {useState} from 'react';
import {Check, Plus, X} from 'lucide-react';

export default function FixtureSelection({fixtures, ids, onChange, disabled}) {
  const [choosing, choose] = useState(false);
  const selected = fixtures.filter(f => ids.includes(f.id));
  return <section className="programmer-selection" aria-label="Fixture selection">
    <header><div><span className="palette-eyebrow">Toolbox</span><h3>Selected fixtures <small>{selected.length}</small></h3></div><button aria-expanded={choosing} disabled={disabled} onClick={() => choose(!choosing)}><Plus size={16}/> Select</button>{selected.length > 0 && <button disabled={disabled} onClick={() => onChange([])}>Clear</button>}</header>
    {selected.length ? <div className="selected-fixture-list">{selected.map(fixture => <button key={fixture.id} disabled={disabled} onClick={() => onChange(ids.filter(id => id !== fixture.id))} aria-label={`Deselect ${fixture.name}`}><Check size={14}/><span>{fixture.name}</span><X size={12}/></button>)}</div> : <p className="palette-muted">Select fixtures to preview and store a look. You can also edit the palette library without a selection.</p>}
    {choosing && <div className="fixture-chooser"><div className="palette-group-buttons">{[...new Set(fixtures.map(f => f.role))].map(role => <button key={role} disabled={disabled} onClick={() => onChange([...new Set([...ids, ...fixtures.filter(f => f.role === role).map(f => f.id)])])}>{role}</button>)}</div><div className="palette-fixture-list">{fixtures.map(fixture => <label key={fixture.id}><input type="checkbox" disabled={disabled} checked={ids.includes(fixture.id)} onChange={event => onChange(event.target.checked ? [...ids, fixture.id] : ids.filter(id => id !== fixture.id))}/><span>{fixture.name}<small>{fixture.role}</small></span></label>)}</div>{!fixtures.length && <p className="palette-muted">Add fixtures to this Load Out first.</p>}</div>}
  </section>;
}
