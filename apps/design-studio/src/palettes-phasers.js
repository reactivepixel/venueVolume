export function validPhaser(p) {
  return !!p && Array.isArray(p.steps) && p.steps.length >= 2 && p.steps.length <= 32
    && Number.isFinite(p.bpm) && p.bpm > 0 && p.bpm <= 600
    && Number.isFinite(p.measure) && p.measure > 0 && p.measure <= 64
    && ['phase','spread'].every(k => Number.isFinite(p[k] ?? 0) && Math.abs(p[k] ?? 0) <= 360000)
    && Number.isFinite(p.transition ?? 1) && (p.transition ?? 1) >= 0 && (p.transition ?? 1) <= 1
    && p.steps.every(s => s && Number.isFinite(s.width ?? 1) && (s.width ?? 1) > 0 && (s.width ?? 1) <= 64
      && ['intensity','pan','tilt'].every(k => s[k] === undefined || (Number.isFinite(s[k]) && Math.abs(s[k]) <= 360))
      && (s.color === undefined || /^#[0-9a-f]{6}$/i.test(s.color)));
}
/** Console-inspired palettes keep static values; phasers cycle weighted steps. */
export function samplePhaser(palette, seconds, index = 0, count = 1) {
  const p = palette.phaser;
  if (!validPhaser(p) || !Number.isFinite(seconds)) return { intensity: palette.intensity, color: palette.color, pan: palette.pan ?? 0, tilt: palette.tilt ?? 0 };
  const total = p.steps.reduce((n, step) => n + Math.max(0.01, step.width ?? 1), 0);
  const phase = (p.phase ?? 0) + (count > 1 ? index / count * (p.spread ?? 0) : 0);
  const cycles = seconds * p.bpm / (60 * p.measure) + phase / 360;
  let position = (cycles - Math.floor(cycles)) * total, stepIndex = 0;
  while (stepIndex < p.steps.length - 1 && position >= (p.steps[stepIndex].width ?? 1)) position -= p.steps[stepIndex++].width ?? 1;
  const a = p.steps[stepIndex], b = p.steps[(stepIndex + 1) % p.steps.length];
  const transition = p.transition ?? 1;
  const mix = transition === 0 ? 0 : Math.max(0, Math.min(1, (position / (a.width ?? 1) - (1 - transition)) / transition));
  const interpolate = (key, fallback) => (a[key] ?? fallback) + ((b[key] ?? fallback) - (a[key] ?? fallback)) * mix;
  const rgb = (hex) => [1, 3, 5].map(n => parseInt((hex || '#ffffff').slice(n, n + 2), 16));
  const from = rgb(a.color ?? palette.color), to = rgb(b.color ?? palette.color);
  const color = '#' + from.map((v, n) => Math.round(v + (to[n] - v) * mix).toString(16).padStart(2, '0')).join('');
  return { intensity: interpolate('intensity', palette.intensity), color, pan: interpolate('pan', palette.pan ?? 0), tilt: interpolate('tilt', palette.tilt ?? 0) };
}
const phaser = (steps, bpm = 60, transition = 1, spread = 0) => ({ steps, bpm, transition, spread, phase: 0, measure: 1 });
export const baselinePalettes = [
  { name: 'Intensity · Full', type: 'Intensity', intensity: 100, color: '#ffffff', attributes: ['intensity'] },
  { name: 'Intensity · Blackout', type: 'Intensity', intensity: 0, color: '#ffffff', attributes: ['intensity'] },
  ...[['White', '#ffffff'], ['Warm', '#ffaa5f'], ['Red', '#ff0000'], ['Blue', '#003cff']].map(([name, color]) => ({ name: `Color · ${name}`, type: 'Color', intensity: 100, color, attributes: ['color'] })),
  { name: 'Position · Center', type: 'Position', intensity: 100, color: '#ffffff', pan: 0, tilt: 0, attributes: ['pan', 'tilt'] },
  { name: 'Phaser · Dimmer chase', type: 'Phaser', intensity: 100, color: '#ffffff', attributes: ['intensity'], phaser: phaser([{ intensity: 100 }, { intensity: 0 }], 60, 0, 360) },
  { name: 'Phaser · Breathe', type: 'Phaser', intensity: 100, color: '#ffffff', attributes: ['intensity'], phaser: phaser([{ intensity: 10 }, { intensity: 100 }], 30) },
  { name: 'Phaser · Red / blue', type: 'Phaser', intensity: 100, color: '#ff0000', attributes: ['color'], phaser: phaser([{ color: '#ff0000' }, { color: '#003cff' }], 60, 0) },
  { name: 'Phaser · Pan sweep', type: 'Phaser', intensity: 100, color: '#ffffff', attributes: ['pan'], phaser: phaser([{ pan: -45 }, { pan: 45 }], 20) },
  { name: 'Phaser · Circle', type: 'Phaser', intensity: 100, color: '#ffffff', attributes: ['pan', 'tilt'], phaser: phaser([{ pan: 0, tilt: -30 }, { pan: 45, tilt: 0 }, { pan: 0, tilt: 30 }, { pan: -45, tilt: 0 }], 20) },
].map(p => ({ ...p, count: 0 }));
