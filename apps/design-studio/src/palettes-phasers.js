export function validPhaser(p) {
  return !!p && Array.isArray(p.steps) && p.steps.length >= 2 && p.steps.length <= 32
    && Number.isFinite(p.bpm) && p.bpm > 0 && p.bpm <= 600
    && Number.isFinite(p.measure) && p.measure > 0 && p.measure <= 64
    && ['phase','spread'].every(k => Number.isFinite(p[k] ?? 0) && Math.abs(p[k] ?? 0) <= 360000)
    && Number.isFinite(p.transition ?? 1) && (p.transition ?? 1) >= 0 && (p.transition ?? 1) <= 1
    && p.steps.every(s => s && Number.isFinite(s.width ?? 1) && (s.width ?? 1) > 0 && (s.width ?? 1) <= 64
      && (s.transition === undefined || Number.isFinite(s.transition) && s.transition >= 0 && s.transition <= 1)
      && (s.curve === undefined || ['linear','sine'].includes(s.curve))
      && ['intensity','pan','tilt'].every(k => s[k] === undefined || (Number.isFinite(s[k]) && (k === 'intensity' ? s[k] >= 0 && s[k] <= 100 : Math.abs(s[k]) <= 180)))
      && (s.color === undefined || /^#[0-9a-f]{6}$/i.test(s.color)));
}
/** Console-inspired palettes keep static values; phasers cycle weighted steps. */
export function samplePhaser(palette, seconds, index = 0, count = 1, library = []) {
  const original = palette.phaser;
  const p = original && {...original, steps: Array.isArray(original.steps) ? original.steps.map(step => {
    const source = step?.paletteName && library.find(p => p.name === step.paletteName && !p.phaser);
    return source ? {...step, ...Object.fromEntries(attributesOf(palette).filter(k => attributesOf(source).includes(k)).map(k => [k, source[k] ?? 0]))} : step;
  }) : original.steps};
  if (!validPhaser(p) || !Number.isFinite(seconds)) return { intensity: palette.intensity, color: palette.color, pan: palette.pan ?? 0, tilt: palette.tilt ?? 0 };
  const total = p.steps.reduce((n, step) => n + Math.max(0.01, step.width ?? 1), 0);
  const phase = (p.phase ?? 0) + (count > 1 ? index / count * (p.spread ?? 0) : 0);
  const cycles = seconds * p.bpm / (60 * p.measure) + phase / 360;
  let position = (cycles - Math.floor(cycles)) * total, stepIndex = 0;
  while (stepIndex < p.steps.length - 1 && position >= (p.steps[stepIndex].width ?? 1)) position -= p.steps[stepIndex++].width ?? 1;
  const b = p.steps[stepIndex], a = p.steps[(stepIndex + p.steps.length - 1) % p.steps.length];
  const transition = b.transition ?? p.transition ?? 1;
  const progress = transition === 0 ? 1 : Math.min(1, position / (b.width ?? 1) / transition);
  const mix = b.curve === 'sine' ? (1 - Math.cos(progress * Math.PI)) / 2 : progress;
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

export const palettePools = ['Intensity', 'Color', 'Position', 'All'];
export const poolAttributes = { Intensity: ['intensity'], Color: ['color'], Position: ['pan', 'tilt'], All: ['intensity', 'color', 'pan', 'tilt'] };
export function attributesOf(palette) { return palette.attributes ?? ['intensity', 'color']; }
export function poolOf(palette) {
  const attributes = attributesOf(palette);
  return palettePools.find(pool => pool !== 'All' && attributes.every(a => poolAttributes[pool].includes(a))) ?? 'All';
}
export function paletteIssue(palette, library = []) {
  if (!palette.name?.trim()) return 'Give the palette a name.';
  if (!attributesOf(palette).length || attributesOf(palette).some(a => !poolAttributes.All.includes(a))) return 'Choose at least one supported attribute.';
  if (!Number.isFinite(palette.intensity) || palette.intensity < 0 || palette.intensity > 100 || !/^#[0-9a-f]{6}$/i.test(palette.color)) return 'Check intensity and color values.';
  if (['pan','tilt'].some(k => !Number.isFinite(palette[k] ?? 0) || Math.abs(palette[k] ?? 0) > 180)) return 'Position must be between −180° and 180°.';
  if (palette.phaser && !validPhaser(palette.phaser)) return 'Check phaser values, speed, measure and step widths.';
  for (const step of palette.phaser?.steps ?? []) {
    if (!step.paletteName) continue;
    const source = library.find(p => p.name === step.paletteName);
    if (!source || source.phaser || source.name === palette.name) return 'Each linked step needs an existing static palette.';
    if (!attributesOf(palette).every(a => attributesOf(source).includes(a))) return 'Step palettes must contain all of this phaser’s attributes.';
  }
  return null;
}
export function createPalette(pool = 'Intensity') {
  return {name: 'New palette', type: pool, intensity: 100, color: '#ffffff', pan: 0, tilt: 0, attributes: [...poolAttributes[pool]], count: 0};
}
export function createPhaser(palette) {
  const first = Object.fromEntries(attributesOf(palette).map(k => [k, palette[k] ?? 0]));
  const second = {...first};
  if ('intensity' in second) second.intensity = 0;
  if ('color' in second) second.color = '#003cff';
  if ('pan' in second) second.pan = 45;
  return {bpm: 60, measure: 1, phase: 0, spread: 0, transition: 1, steps: [{...first, width: 1}, {...second, width: 1}]};
}
/** Keep independent layers; discard an older reference only when fully replaced. */
export function layeredNames(names, palette, library) {
  const attributes = attributesOf(palette);
  return [...names.filter(name => name !== palette.name && !attributesOf(library.find(p => p.name === name) ?? {}).every(a => attributes.includes(a))), palette.name];
}
export function renamePaletteReferences(data, palette, originalName) {
  const rename = name => name === originalName ? palette.name : name;
  const presets = (originalName ? data.presets.map(p => p.name === originalName ? palette : p) : [...data.presets, palette])
    .map(p => p.phaser ? {...p, phaser: {...p.phaser, steps: p.phaser.steps.map(s => ({...s, ...(s.paletteName ? {paletteName: rename(s.paletteName)} : {})}))}} : p);
  const script = data.script.map(entry => ({...entry, preset: rename(entry.preset), assignments: entry.assignments?.map(a => ({...a, preset: rename(a.preset), ...(a.paletteNames ? {paletteNames: a.paletteNames.map(rename)} : {})}))}));
  for (const p of presets) {
    const issue = paletteIssue(p, presets);
    if (issue && (p.name === palette.name || p.phaser?.steps.some(s => s.paletteName === palette.name))) throw new Error(issue);
  }
  const macros = data.macros?.map(macro => ({...macro, lines: macro.lines.map(line => ({...line, paletteName: rename(line.paletteName)}))}));
  return {presets, script, ...(macros ? {macros} : {})};
}
/** Store fixture-level references in a cue while preserving its group defaults. */
export function applyPaletteToCue(script, entryId, fixtureIds, palette, fixtures, library) {
  if (!fixtureIds.length) return script;
  return script.map(entry => {
    if (entry.entryId !== entryId) return entry;
    const assignments = [...(entry.assignments ?? [])];
    for (const fixture of fixtures.filter(f => fixtureIds.includes(f.id))) {
      const index = assignments.findIndex(a => a.fixtureId === fixture.id);
      const original = assignments[index] ?? {fixtureId: fixture.id};
      const names = original.paletteNames ?? (original.preset ? [original.preset] : []);
      const paletteNames = layeredNames(names, palette, library);
      const next = {...original, paletteNames, preset: palette.name, paletteSnapshots: (original.paletteSnapshots ?? []).filter(p => !attributesOf(p).some(a => attributesOf(palette).includes(a)))};
      if (index >= 0) assignments[index] = next; else assignments.push(next);
    }
    return {...entry, assignments};
  });
}
