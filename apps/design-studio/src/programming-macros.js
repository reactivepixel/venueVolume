import {applyPaletteToCue, paletteIssue} from './palettes-phasers.js';

export const starterMacros = [
  {id:'warm-wash',name:'Full warm wash',target:{kind:'selection'},lines:[{paletteName:'Intensity · Full',enabled:true},{paletteName:'Color · Warm',enabled:true}]},
  {id:'cool-breathe',name:'Cool breathing wash',target:{kind:'selection'},lines:[{paletteName:'Color · Blue',enabled:true},{paletteName:'Phaser · Dimmer breathe',enabled:true}]},
];
export function macroIssue(macro) {
  if (!macro?.name?.trim() || macro.name.length > 120) return 'Use a macro name of 1–120 characters.';
  if (!['selection','role'].includes(macro.target?.kind)) return 'Choose a fixture target.';
  if (!Array.isArray(macro.lines) || !macro.lines.length || macro.lines.length > 32) return 'Add 1–32 action rows.';
  const enabled = macro.lines.filter(line => line.enabled);
  if (!enabled.length || enabled.some(line => !line.paletteName)) return 'Choose a saved palette for every enabled action.';
  return null;
}
/** Resolve once, preflight all rows, then return one immutable cue update. */
export function planMacro(macro, {selection = [], fixtures, palettes, script, entryId}) {
  const issue = macroIssue(macro); if (issue) throw new Error(issue);
  if (!script.some(entry => entry.entryId === entryId)) throw new Error('Choose a destination cue.');
  const ids = [...new Set(macro.target.kind === 'role' ? fixtures.filter(f => f.role === macro.target.role).map(f => f.id) : selection)];
  if (!ids.length) throw new Error('Select fixtures or choose a populated fixture role.');
  if (ids.some(id => !fixtures.some(f => f.id === id))) throw new Error('Some target fixtures are no longer available.');
  const actions = macro.lines.filter(line => line.enabled).map(line => {
    const palette = palettes.find(p => p.name === line.paletteName);
    if (!palette) throw new Error(`Missing palette: ${line.paletteName}. Repair the action before running.`);
    const issue = paletteIssue(palette, palettes); if (issue) throw new Error(issue);
    return palette;
  });
  return {ids, actions, script:actions.reduce((next, palette) => applyPaletteToCue(next,entryId,ids,palette,fixtures,palettes), script)};
}
