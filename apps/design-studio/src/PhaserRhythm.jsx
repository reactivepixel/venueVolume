import React, {useRef} from 'react';
import {attributesOf, samplePhaser} from './palettes-phasers';

export default function PhaserRhythm({draft, palettes, stepIndex, selectStep, updatePhaser}) {
  const taps = useRef([]), phaser = draft.phaser;
  const first = Math.floor(stepIndex / 8) * 8, count = Math.min(8,phaser.steps.length-first);
  const tap = () => {const now=performance.now()/1000;if(taps.current.length&&now-taps.current.at(-1)>2)taps.current=[];taps.current=[...taps.current,now].slice(-6);if(taps.current.length>1)updatePhaser({bpm:Math.min(600,Math.max(1,60*(taps.current.length-1)/(now-taps.current[0])))});};
  const points = Array.from({length:121},(_,i)=>{
    const value=samplePhaser(draft,i/120*60*phaser.measure/phaser.bpm,0,1,palettes);
    const attrs=attributesOf(draft);
    const y=attrs.includes('intensity')?value.intensity/100:attrs.includes('color')?parseInt(value.color.slice(1,3),16)/255:(value.pan+180)/360;
    return `${i/120*500},${98-y*96}`;
  }).join(' ');
  const pattern = name => {if(!window.confirm(`${name} replaces the steps and distribution. Keep tempo and cycle length?`))return;updatePhaser({steps:[{intensity:0,width:1,curve:'sine'},{intensity:100,width:1,curve:'sine'}],transition:name==='Pulse'?0:1,spread:name==='Wave'?360:0});selectStep(0);};
  return <div className="phaser-rhythm">
    <div className="tempo-controls"><div className="tempo-ring"><button className="tempo-tap" onClick={tap}><strong>{Math.round(phaser.bpm)}</strong><span>BPM · Tap tempo</span></button>{Array.from({length:count},(_,i)=>{const angle=i/count*Math.PI*2-Math.PI/2,index=first+i;return <button key={index} aria-label={`Select step ${index+1}`} aria-pressed={index===stepIndex} style={{left:`${150+Math.cos(angle)*120}px`,top:`${150+Math.sin(angle)*120}px`}} onClick={()=>selectStep(index)}>{index+1}</button>;})}</div>
      {phaser.steps.length>8&&<select aria-label="Step bank" value={first/8} onChange={e=>selectStep(+e.target.value*8)}>{Array.from({length:Math.ceil(phaser.steps.length/8)},(_,i)=><option key={i} value={i}>Steps {i*8+1}–{Math.min(phaser.steps.length,i*8+8)}</option>)}</select>}
      <label>Steps · {phaser.steps.length}<input type="range" aria-label="Step count" min="2" max="32" value={phaser.steps.length} onChange={e=>{const count=+e.target.value,steps=Array.from({length:count},(_,i)=>structuredClone(phaser.steps[i]??phaser.steps.at(-1)));updatePhaser({steps});selectStep(Math.min(stepIndex,count-1));}}/></label>
      <div className="palette-quick">{[2,4,8,16].map(beats=><button key={beats} aria-pressed={phaser.measure===beats} onClick={()=>updatePhaser({measure:beats})}>{beats===2?'½ bar':`${beats/4} bar${beats>4?'s':''}`}</button>)}</div><p className="palette-muted">4/4 · bar shortcuts change loop length, independently of step count.</p>
    </div>
    <div><div className="palette-section-heading"><h3>Cycle preview</h3><span>{(60*phaser.measure/phaser.bpm).toFixed(2)} s</span></div><svg role="img" aria-label="Phaser curve over one cycle" viewBox="0 0 500 100"><polyline points={points} fill="none" stroke="currentColor" strokeWidth="2"/></svg>
      {attributesOf(draft).length===1&&attributesOf(draft)[0]==='intensity'&&<div className="palette-quick"><span>Pattern</span>{['Wave','Breathe','Pulse'].map(name=><button key={name} onClick={()=>pattern(name)}>{name}</button>)}</div>}
      <p className="palette-muted">Select a numbered step to edit its source and transition. Linked presets follow source updates.</p>
    </div>
  </div>;
}
