import React, {useEffect, useRef, useState} from 'react';
import {ChevronDown, Copy, MoreHorizontal, Save} from 'lucide-react';
import {attributesOf, createPalette, createPhaser, paletteIssue, palettePools, poolAttributes, poolOf} from './palettes-phasers';
import {assignmentPalettes} from './live-model';
import {Button, Field} from './components';
import MacroWorkbench from './MacroWorkbench';
import PhaserRhythm from './PhaserRhythm';
import FixtureSelection from './programming/FixtureSelection';
import CueNavigator from './programming/CueNavigator';
import PalettePreview, {PaletteSwatch} from './programming/PalettePreview';
import {cueAt, cueLabel, ensureCue} from './programming/cues';
import './palettes.css';

const labels = {intensity:'Dimmer', color:'Color', pan:'Pan', tilt:'Tilt', zoom:'Beam zoom'};
export default function PaletteWorkbench({palettes, fixtures = [], script = [], macros, currentCue = 1, onCurrentCue, onStoreCue, onSaveMacro, onApplyMacro, onSave}) {
  const initial = palettes[0] ?? createPalette();
  const [selected, select] = useState(initial.name);
  const [draft, edit] = useState(() => structuredClone(initial));
  const [saved, remember] = useState(() => JSON.stringify(initial));
  const [pool, setPool] = useState('All pools');
  const [query, search] = useState('');
  const [kind, setKind] = useState('All');
  const [stepIndex, selectStep] = useState(null);
  const [ids, setIds] = useState([]);
  const [seconds, clock] = useState(0);
  const [playing, play] = useState(() => !window.matchMedia('(prefers-reduced-motion: reduce)').matches);
  const [notice, notify] = useState('');
  const [busy, setBusy] = useState(false);
  const [pending, setPending] = useState(null);
  const [touched, touch] = useState(false);
  const [cueSaved, setCueSaved] = useState('');
  const [destination, setDestination] = useState(currentCue);
  const [showStore, setShowStore] = useState(false);
  const [contextExpanded, expandContext] = useState(false);
  const [recentSteps, setRecentSteps] = useState([]);
  const currentIds = ids.filter(id => fixtures.some(f => f.id === id));
  const selectionKey = currentIds.join(',');
  const selectedFixtures = fixtures.filter(f => currentIds.includes(f.id));
  const targetEntry = cueAt(script, currentCue) ?? {cueNumber:currentCue, assignments:[]};
  const dirty = JSON.stringify(draft) !== saved;
  const issue = paletteIssue(draft, palettes);
  const signature = JSON.stringify([currentCue, currentIds, draft]);
  const cueDirty = touched && currentIds.length > 0 && signature !== cueSaved;
  const currentStep = stepIndex === null ? null : draft.phaser?.steps[stepIndex];
  const filtered = palettes.filter(p => (pool === 'All pools' || poolOf(p) === pool) && (kind === 'All' || !!p.phaser === (kind === 'Dynamic')) && p.name.toLowerCase().includes(query.toLowerCase()));
  const callbacks = useRef();
  callbacks.current = {onStoreCue, draft, ids:currentIds, number:currentCue, cueDirty, signature, issue};
  const latestScript = useRef(script);
  latestScript.current = script;
  const saveQueue = useRef(Promise.resolve());
  function persistCue(number = callbacks.current.number) {
    const state = callbacks.current;
    if (!state.ids.length || state.issue) return Promise.resolve(false);
    const operation = saveQueue.current.catch(() => {}).then(() => state.onStoreCue(state.draft, state.ids, number));
    saveQueue.current = operation;
    return operation.then(result => {if (result?.script) latestScript.current = result.script; if (number === state.number) setCueSaved(state.signature); return true;}).catch(error => {notify(error.message || 'Cue could not be stored.'); return false;});
  }
  async function flushCue() {
    return !callbacks.current.cueDirty || await persistCue();
  }
  useEffect(() => {
    if (!cueDirty || issue) return;
    const timer = setTimeout(() => persistCue(), 450);
    return () => clearTimeout(timer);
  }, [draft, selectionKey, currentCue, cueDirty, issue]);
  useEffect(() => () => {
    const state = callbacks.current;
    if (state.cueDirty && !state.issue && state.ids.length) {
      saveQueue.current.catch(() => {}).then(() => state.onStoreCue(state.draft, state.ids, state.number))
        .catch(error => console.error('Cue edit could not be stored.', error));
    }
  }, []);
  useEffect(() => {
    if (!playing) return;
    const start = performance.now() - seconds * 1000;
    const timer = setInterval(() => clock((performance.now() - start) / 1000), 50);
    return () => clearInterval(timer);
  }, [playing]);
  const update = patch => {edit(previous => ({...previous, ...patch})); touch(true);};
  const updatePhaser = patch => {edit(previous => ({...previous, phaser:{...previous.phaser, ...patch}})); touch(true);};
  const updateStep = (patch, replace = false) => {
    if (!currentStep) return;
    updatePhaser({steps:draft.phaser.steps.map((step,index) => index === stepIndex ? replace ? {...patch} : {...step, ...patch} : step)});
  };
  function load(palette, preview = true) {
    select(palettes.some(p => p.name === palette.name) ? palette.name : undefined);
    edit(structuredClone(palette)); remember(JSON.stringify(palette)); selectStep(null); touch(preview); notify('');
  }
  function recallSelection(nextIds, number, cues = latestScript.current) {
    const fixture = fixtures.find(f => nextIds.includes(f.id));
    const entry = cueAt(cues, number) ?? {cueNumber:number, assignments:[]};
    const layers = fixture ? assignmentPalettes({presets:palettes, script:cues}, entry, fixture) : [];
    if (layers.length) load(layers.at(-1), false);
    else if (fixture) load({...createPalette('All'), name:`Cue ${cueLabel(number)}`, intensity:0}, false);
    touch(false);
  }
  const changing = useRef(false);
  async function changeSelection(next) {
    if (changing.current) return;
    changing.current = true; setBusy(true);
    try {
      if (!await flushCue()) return;
      setIds(next); recallSelection(next, currentCue); expandContext(false);
    } finally { changing.current = false; setBusy(false); }
  }
  async function changeCue(number) {
    if (changing.current) return;
    changing.current = true; setBusy(true);
    try {
      if (!await flushCue()) return;
      const state = await onCurrentCue(number);
      recallSelection(currentIds, number, state?.script ?? script); setDestination(number); clock(0);
    } finally { changing.current = false; setBusy(false); }
  }
  const navigate = action => {if (dirty && !currentIds.length) setPending({action}); else action();};
  async function saveLibrary() {
    if (busy || issue) return false;
    if (palettes.some(p => p.name === draft.name.trim() && p.name !== selected)) {notify('Choose a unique palette name.'); return false;}
    setBusy(true);
    try {
      const palette = {...draft, name:draft.name.trim(), type:poolOf(draft)};
      await onSave(palette, selected); select(palette.name); remember(JSON.stringify(palette)); edit(palette);
      notify('Stored in the preset pool. Ready to recall on any selection.'); return true;
    } catch (error) {notify(error.message || 'Could not store palette.'); return false;}
    finally {setBusy(false);}
  }
  const newPalette = () => {select(undefined); edit(createPalette(pool === 'All pools' ? 'Intensity' : pool)); remember(''); selectStep(null); touch(false);};
  const valueControl = (key, value, set) => <Field key={key} label={labels[key]}>{key === 'color'
    ? <div className="palette-color-value"><input aria-label="Color value" type="color" value={value || '#ffffff'} onChange={e => set(e.target.value)}/><code>{value}</code></div>
    : <div className="palette-value"><input aria-label={`${labels[key]} value`} type="range" min={['intensity','zoom'].includes(key) ? 0 : -180} max={['intensity','zoom'].includes(key) ? 100 : 180} value={value ?? 0} onChange={e => set(+e.target.value)}/><input aria-label={`${labels[key]} numeric value`} type="number" min={['intensity','zoom'].includes(key) ? 0 : -180} max={['intensity','zoom'].includes(key) ? 100 : 180} value={value ?? 0} onChange={e => set(+e.target.value)}/><span>{['intensity','zoom'].includes(key) ? '%' : '°'}</span></div>}</Field>;
  const macroScript = ensureCue(script, currentCue);
  return <section className="palette-console" aria-label="Palette programmer">
    <FixtureSelection fixtures={fixtures} ids={currentIds} onChange={changeSelection} disabled={busy}/>
    <aside className="palette-pools">
      <header className="palette-section-heading"><h2>Preset pools</h2><span>{palettes.length}</span></header>
      <input aria-label="Search palettes" placeholder="Find a palette…" value={query} onChange={e => search(e.target.value)}/>
      <nav className="palette-pool-tabs" aria-label="Attribute pools">{['All pools', ...palettePools].map(name => <button key={name} aria-pressed={pool === name} onClick={() => setPool(name)}>{name}</button>)}</nav>
      <div className="palette-kind-tabs">{['All','Static','Dynamic'].map(name => <button key={name} aria-pressed={kind === name} onClick={() => setKind(name)}>{name}</button>)}</div>
      <div className="palette-pool-list">{filtered.map(palette => <button key={palette.name} className="palette-pool-cell" aria-pressed={selected === palette.name} onClick={() => navigate(async () => {if (await flushCue()) load(palette);})}>
        <PaletteSwatch palette={palette} palettes={palettes} seconds={seconds}/><span><strong>{palette.name.replace(/^(Intensity|Color|Position|Beam|All|Phaser) · /,'')}</strong><small>{poolOf(palette)} · {palette.phaser ? `${palette.phaser.steps.length} steps` : 'Static'}</small></span><em>{String(palettes.indexOf(palette) + 1).padStart(2,'0')}</em>
      </button>)}</div>
      {!filtered.length && <p className="palette-muted">No matching palettes.</p>}
      <Button onClick={() => navigate(async () => {if (await flushCue()) newPalette();})}>+ New palette</Button>
    </aside>
    <div className="palette-programmer">
      <header className="palette-editor-heading"><div><p className="palette-eyebrow">{poolOf(draft)} pool</p><h2>{draft.name.replace(/^(Intensity|Color|Position|Beam|All|Phaser) · /,'')}</h2></div><div className="palette-mode" aria-label="Palette mode"><button aria-pressed={!draft.phaser} onClick={() => {update({phaser:undefined}); selectStep(null);}}>Static</button><button aria-pressed={!!draft.phaser} onClick={() => {if (!draft.phaser) update({phaser:createPhaser(draft)});}}>Dynamic</button></div></header>
      <PalettePreview draft={draft} previewDraft={touched} palettes={palettes} script={script} fixtures={selectedFixtures} allFixtures={fixtures} entry={targetEntry} seconds={seconds} playing={playing} onPlay={play} onRestart={() => {clock(0); play(false);}}/>
      {draft.phaser ? <>
        <PhaserRhythm draft={draft} palettes={palettes} stepIndex={stepIndex} selectStep={selectStep} updatePhaser={updatePhaser}/>
        {currentStep && <section className="palette-step-editor"><header className="palette-section-heading"><h3>Step {stepIndex + 1}</h3><button onClick={() => selectStep(null)}>Close step</button></header>
          <div className="palette-top-fields"><Field label="Preset reference"><select value={currentStep.paletteName ?? ''} onChange={e => updateStep({paletteName:e.target.value || undefined})}><option value="">Custom values</option>{palettes.filter(p => !p.phaser && p.name !== selected && attributesOf(draft).every(a => attributesOf(p).includes(a))).map(p => <option key={p.name}>{p.name}</option>)}</select></Field><Field label="Width"><input type="number" min="0.1" max="64" step="0.1" value={currentStep.width ?? 1} onChange={e => updateStep({width:+e.target.value})}/></Field></div>
          {currentStep.paletteName ? <p className="palette-reference">Linked to {currentStep.paletteName}</p> : <div className="palette-attributes">{attributesOf(draft).map(key => valueControl(key, currentStep[key] ?? draft[key], value => updateStep({[key]:value})))}</div>}
          <div className="palette-top-fields"><Field label="Transition (%)"><input type="number" min="0" max="100" value={(currentStep.transition ?? draft.phaser.transition ?? 1) * 100} onChange={e => updateStep({transition:+e.target.value / 100})}/></Field><Field label="Curve"><select value={currentStep.curve ?? 'linear'} onChange={e => updateStep({curve:e.target.value})}><option value="linear">Linear</option><option value="sine">Sine</option></select></Field></div>
          <div className="palette-quick"><button onClick={() => updateStep({transition:0})}>Hold</button><button onClick={() => updateStep({transition:1, curve:'sine'})}>Smooth fade</button><button onClick={() => setRecentSteps(old => [structuredClone(currentStep), ...old].slice(0,4))}>Remember step</button>{recentSteps.map((step,index) => <button key={index} onClick={() => updateStep(step, true)}>Recent {index + 1}</button>)}</div>
        </section>}
        <details className="palette-distribution"><summary>Timing & distribution <ChevronDown size={15}/></summary><div className="palette-timing">{[['bpm','BPM',1,600],['measure','Beats per cycle',0.25,64],['phase','Phase (°)',-360,360],['spread','Spread (°)',-360,360]].map(([key,label,min,max]) => <Field key={key} label={label}><input type="number" min={min} max={max} value={draft.phaser[key] ?? 0} onChange={e => updatePhaser({[key]:+e.target.value})}/></Field>)}</div><div className="palette-quick"><button onClick={() => updatePhaser({spread:0})}>Together</button><button onClick={() => updatePhaser({spread:360})}>Wave 0–360°</button><button onClick={() => updatePhaser({spread:-360})}>Reverse</button></div></details>
      </> : <section className="palette-attributes">{attributesOf(draft).map(key => valueControl(key, draft[key], value => update({[key]:value})))}</section>}
      <details className="palette-library-settings"><summary>Store in preset pool <ChevronDown size={15}/></summary><div className="palette-top-fields"><Field label="Palette name"><input value={draft.name} onChange={e => update({name:e.target.value})}/></Field><Field label="Attribute pool"><select value={poolOf(draft)} onChange={e => {const category=e.target.value;update({type:category, attributes:[...poolAttributes[category]], phaser:undefined});selectStep(null);}}>{palettePools.map(name => <option key={name}>{name}</option>)}</select></Field></div><div className="row-actions"><Button onClick={() => {select(undefined);update({name:`${draft.name} copy`});remember('');}}><Copy size={15}/>Duplicate</Button><Button primary disabled={busy || !!issue} onClick={saveLibrary}><Save size={15}/>{selected ? 'Update palette' : 'Store palette'}</Button></div></details>
      {issue && <p className="palette-validation" role="alert">{issue}</p>}
      <p className="palette-status" role="status">{notice}</p>
    </div>
    <MacroWorkbench macros={macros} palettes={palettes} fixtures={fixtures} selection={currentIds} script={macroScript} entryId={cueAt(macroScript,currentCue).entryId} onStore={onSaveMacro} onApply={async transform => {
      if (!await flushCue()) throw new Error('Fix the cue edit before running a macro.');
      const state = await onApplyMacro(current => transform(ensureCue(current, currentCue)));
      recallSelection(currentIds, currentCue, state.script);
    }}/>
    <footer className={`programmer-context-bar ${!currentIds.length && !contextExpanded ? 'compact' : ''}`}><button aria-label={contextExpanded ? 'Collapse context bar' : 'Expand context bar'} aria-expanded={contextExpanded} onClick={() => expandContext(!contextExpanded)}><MoreHorizontal size={20}/></button>{(!!currentIds.length || contextExpanded) && <><CueNavigator number={currentCue} script={script} onSelect={changeCue} disabled={busy}/><span>{currentIds.length ? `${currentIds.length} fixtures · ${cueDirty ? 'Saving edits…' : 'Edits saved to this cue'}` : 'Select fixtures to store a cue'}</span><Button primary disabled={!currentIds.length || !!issue || busy} onClick={async () => {if (await persistCue()) notify(`Stored in cue ${cueLabel(currentCue)}.`);}}>Store cue {cueLabel(currentCue)}</Button><button aria-expanded={showStore} onClick={() => {setDestination(currentCue);setShowStore(!showStore);}}>Store to…</button>
      {showStore && <div className="cue-store-menu"><Field label="Save on specific cue"><select value={destination} onChange={e => setDestination(+e.target.value)}>{Array.from({length:255},(_,i) => i + 1).map(number => <option key={number} value={number}>Cue {cueLabel(number)}</option>)}</select></Field><Button primary disabled={!currentIds.length || !!issue} onClick={async () => {if (await persistCue(destination)) {notify(`Stored in cue ${cueLabel(destination)}.`);setShowStore(false);}}}>Store selected fixtures</Button></div>}
    </>}</footer>
    {pending && <div className="palette-dialog-backdrop"><section role="alertdialog" aria-modal="true" aria-label="Unsaved palette changes" className="palette-dialog"><h2>Store palette changes?</h2><p>This library draft is not applied to any fixtures.</p><div className="row-actions"><Button onClick={() => setPending(null)}>Keep editing</Button><Button onClick={() => {pending.action();setPending(null);}}>Discard</Button><Button primary disabled={busy || !!issue} onClick={async () => {if (await saveLibrary()) {pending.action();setPending(null);}}}>Store and continue</Button></div></section></div>}
  </section>;
}
