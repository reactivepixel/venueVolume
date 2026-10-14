import React, {useEffect, useState} from 'react';
import {Button, Field} from './components';
import {macroIssue, planMacro, starterMacros} from './programming-macros';

export default function MacroWorkbench({macros = starterMacros, palettes, fixtures, selection, script, entryId, onStore, onApply}) {
  const [draft,setDraft] = useState(() => structuredClone(macros[0]));
  const [saved,setSaved] = useState(() => JSON.stringify(macros[0]));
  const [message,setMessage] = useState('');
  const [busy,setBusy] = useState(false);
  const [lastRun,setLastRun] = useState(null);
  const [pending,setPending] = useState(null);
  let plan, error;
  try { plan = planMacro(draft,{selection,fixtures,palettes,script,entryId}); } catch(e) { error=e.message; }
  const dirty = JSON.stringify(draft) !== saved;
  useEffect(()=>{const current=macros.find(m=>m.id===draft.id);if(!dirty&&current&&JSON.stringify(current)!==saved){setDraft(structuredClone(current));setSaved(JSON.stringify(current));}},[macros,dirty,draft.id,saved]);
  const edit = patch => setDraft(d => ({...d,...patch}));
  const line = (index,patch) => edit({lines:draft.lines.map((l,i) => i===index ? {...l,...patch} : l)});
  const load = macro => {setDraft(structuredClone(macro));setSaved(macros.some(m => m.id===macro.id) ? JSON.stringify(macro) : '');setMessage('');};
  const navigate = macro => { if(dirty) setPending(macro); else load(macro); };
  const store = async () => { if(macroIssue(draft)) return false; setBusy(true);try {await onStore(draft);setSaved(JSON.stringify(draft));setMessage('Stored macro.');return true;} catch(e){setMessage(e.message);return false;} finally{setBusy(false);} };
  const run = async () => {if(!plan || busy || dirty)return;setBusy(true);try{await onApply(plan.script);setLastRun({before:script,after:JSON.stringify(plan.script)});setMessage(`Applied ${plan.actions.length} actions to ${plan.ids.length} fixtures.`);}catch(e){setMessage(e.message);}finally{setBusy(false);} };
  const undo = async () => {if(!lastRun || lastRun.after!==JSON.stringify(script))return;setBusy(true);try{await onApply(lastRun.before);setLastRun(null);setMessage('Undid the whole macro run.');}catch(e){setMessage(e.message);}finally{setBusy(false);} };
  return <details className="macro-workbench"><summary>Macros · repeat a palette workflow</summary><div className="macro-editor">
    <p className="palette-muted">Store a named list of palette recalls. Each run resolves one target and applies all enabled rows together to the selected cue.</p>
    <div className="row-actions"><Field label="Macro pool"><select value={macros.some(m=>m.id===draft.id)?draft.id:''} onChange={e=>navigate(macros.find(m=>m.id===e.target.value))}><option value="" disabled>New macro</option>{macros.map(m=><option key={m.id} value={m.id}>{m.name}</option>)}</select></Field><Button onClick={()=>navigate({id:crypto.randomUUID(),name:'New macro',target:{kind:'selection'},lines:[{paletteName:'',enabled:true}]})}>New macro</Button></div>
    <div className="palette-top-fields"><Field label="Macro name"><input value={draft.name} onChange={e=>edit({name:e.target.value})}/></Field><Field label="Macro target"><select value={draft.target.kind==='selection'?'selection':`role:${draft.target.role}`} onChange={e=>edit({target:e.target.value==='selection'?{kind:'selection'}:{kind:'role',role:e.target.value.slice(5)}})}><option value="selection">Current selection · {selection.length}</option>{[...new Set(fixtures.map(f=>f.role))].map(role=><option key={role} value={`role:${role}`}>Role · {role}</option>)}</select></Field></div>
    {draft.lines.map((l,i)=><div className="macro-line" key={i}><input aria-label={`Enable action ${i+1}`} type="checkbox" checked={l.enabled} onChange={e=>line(i,{enabled:e.target.checked})}/><b>{i+1}</b><Field label="Apply saved palette"><select value={l.paletteName} onChange={e=>line(i,{paletteName:e.target.value})}><option value="">Choose palette</option>{palettes.map(p=><option key={p.name}>{p.name}</option>)}{l.paletteName&&!palettes.some(p=>p.name===l.paletteName)&&<option value={l.paletteName}>Missing · {l.paletteName}</option>}</select></Field><Button disabled={!i} onClick={()=>{const lines=[...draft.lines];[lines[i-1],lines[i]]=[lines[i],lines[i-1]];edit({lines});}}>Move up</Button><Button disabled={draft.lines.length===1} onClick={()=>edit({lines:draft.lines.filter((_,j)=>j!==i)})}>Remove</Button></div>)}
    <Button disabled={draft.lines.length>=32} onClick={()=>edit({lines:[...draft.lines,{paletteName:'',enabled:true}]})}>Add action</Button>
    <p role="status">{error || `Ready · ${plan.ids.length} fixtures · ${plan.actions.map(p=>p.name).join(' → ')}`}</p>
    <div className="row-actions"><Button disabled={busy||!!macroIssue(draft)} onClick={store}>Store macro</Button><Button primary disabled={busy||dirty||!plan} onClick={run}>Run macro</Button><Button disabled={busy||!lastRun||lastRun.after!==JSON.stringify(script)} onClick={undo}>Undo macro</Button></div><p role="status">{message || (dirty?'Store your macro before running.':'')}</p>
    {pending&&<div className="palette-dialog-backdrop"><section role="alertdialog" aria-modal="true" aria-label="Unsaved macro changes" className="palette-dialog"><h2>Store macro changes?</h2><div className="row-actions"><Button onClick={()=>setPending(null)}>Keep editing</Button><Button onClick={()=>{load(pending);setPending(null);}}>Discard</Button><Button disabled={busy||!!macroIssue(draft)} onClick={async()=>{if(await store()){load(pending);setPending(null);}}}>Store and continue</Button></div></section></div>}
  </div></details>;
}
