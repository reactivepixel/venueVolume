import React, {useEffect, useRef, useState} from 'react';
import {ChevronLeft, ChevronRight, ListOrdered} from 'lucide-react';
import {cueAt, cueLabel} from './cues';

export default function CueNavigator({number, script, onSelect, disabled = false}) {
  const [open, setOpen] = useState(false);
  const current = useRef(null);
  useEffect(() => { if (open) current.current?.scrollIntoView({block:'nearest'}); }, [open]);
  return <div className="cue-navigator">
    <button aria-label="Previous cue" disabled={disabled || number === 1} onClick={() => onSelect(number - 1)}><ChevronLeft size={18}/></button>
    <button className="cue-current" aria-expanded={open} onClick={() => setOpen(!open)} disabled={disabled}><ListOrdered size={17}/><span>Cue <b>{cueLabel(number)}</b></span></button>
    <button aria-label="Next cue" disabled={disabled || number === 255} onClick={() => onSelect(number + 1)}><ChevronRight size={18}/></button>
    {open && <div className="cue-browser" aria-label="Cues 01–255"><header><strong>Cues</strong><button aria-label="Close cue list" onClick={() => setOpen(false)}>×</button></header><div className="cue-browser-list">{Array.from({length:255}, (_,i) => i + 1).map(cue => {
      const entry = cueAt(script, cue);
      return <button key={cue} ref={cue === number ? current : undefined} aria-current={cue === number ? 'step' : undefined} onClick={async () => {await onSelect(cue); setOpen(false);}}><b>{cueLabel(cue)}</b><span>{entry?.name || 'Empty cue'}</span>{entry && <i/>}</button>;
    })}</div></div>}
  </div>;
}
