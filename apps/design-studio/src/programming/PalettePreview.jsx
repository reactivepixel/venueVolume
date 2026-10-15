import React from 'react';
import {Pause, Play, RotateCcw} from 'lucide-react';
import {attributesOf, samplePhaser} from '../palettes-phasers';
import {assignmentPalettes} from '../live-model';

export function PaletteSwatch({palette, palettes, seconds}) {
  return <span className="palette-swatch" aria-hidden="true">{Array.from({length:12}, (_,index) => {
    const value = samplePhaser(palette, seconds, index, 12, palettes);
    return <i key={index} style={{background: attributesOf(palette).includes('color') ? value.color : '#d2e9f0', opacity: attributesOf(palette).includes('intensity') ? Math.max(0.06, value.intensity / 100) : 1}}/>;
  })}</span>;
}

export default function PalettePreview({draft, previewDraft, palettes, script, fixtures, entry, seconds, playing, onPlay, onRestart}) {
  const visible = fixtures.length ? fixtures.slice(0, 8) : Array.from({length:4}, (_,i) => ({id:`sample-${i}`, name:`Sample ${i + 1}`}));
  return <section className="palette-live" aria-label="Live fixture preview"><header><strong>Live preview</strong><span>{fixtures.length ? `${fixtures.length} selected fixtures` : '4 sample fixtures'}</span><button aria-label={playing ? 'Pause preview and fixtures' : 'Play preview and fixtures'} onClick={() => onPlay(!playing)}>{playing ? <Pause size={17}/> : <Play size={17}/>}</button><button aria-label="Restart preview" onClick={onRestart}><RotateCcw size={16}/></button></header>
    <div className="fixture-output-strip">{visible.map((fixture,index) => {
      const layers = [...assignmentPalettes({presets:palettes, script}, entry, fixture), ...(previewDraft || !fixtures.length ? [draft] : [])];
      const value = layers.reduce((output,palette) => {
        const sample = samplePhaser(palette, seconds, index, fixtures.length || 4, palettes);
        return {...output, ...Object.fromEntries(attributesOf(palette).map(attribute => [attribute, sample[attribute]]))};
      }, {intensity:fixtures.length ? 0 : 100, color:'#ffffff', pan:0, tilt:0, zoom:50});
      return <div className="fixture-output" key={fixture.id} title={`${fixture.name} · ${Math.round(value.intensity)}%`}><div className="fixture-light" style={{'--light':value.color, '--level':value.intensity / 100, '--pan':`${value.pan / 8}px`, '--tilt':`${value.tilt / 8}deg`, '--beam-inset':`${42 - value.zoom * .38}%`}}><i/><b/></div><span>{fixture.name}</span><small>{Math.round(value.intensity)}%</small></div>;
    })}</div>
  </section>;
}
