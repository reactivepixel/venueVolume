import { attributesOf, paletteIssue, subtractAttributes } from '../palettes-phasers.js';
import {normalizeScript} from '../model.js';

export const cueLabel = number => String(number).padStart(2, '0');
export function cueAt(script, number) {
  return script.find((entry, index) => (entry.cueNumber ?? index + 1) === number);
}
export function ensureCue(script, number) {
  if (!Number.isInteger(number) || number < 1 || number > 255) throw new Error('Choose a cue from 01–255.');
  const numbered = script.map((entry, index) => ({...entry, cueNumber: entry.cueNumber ?? index + 1}));
  if (cueAt(numbered, number)) return numbered;
  return normalizeScript([...numbered, {entryId: crypto.randomUUID(), cueNumber: number, name: `Cue ${cueLabel(number)}`, assignments: [], fade: 0, hold: 0, trigger: 'Manual'}]
    .sort((a, b) => a.cueNumber - b.cueNumber));
}
/** A cue draft is independent of the reusable library; only owned attributes change. */
export function storeCueDraft(script, number, ids, palette, fixtures, library) {
  const issue = paletteIssue(palette, library);
  if (issue) throw new Error(issue);
  const targets = fixtures.filter(fixture => ids.includes(fixture.id));
  if (!targets.length) throw new Error('Select fixtures before storing a cue.');
  const attributes = attributesOf(palette);
  return ensureCue(script, number).map(entry => {
    if (entry.cueNumber !== number) return entry;
    const assignments = [...(entry.assignments ?? [])];
    for (const fixture of targets) {
      const index = assignments.findIndex(item => item.fixtureId === fixture.id);
      const previous = index < 0 ? {fixtureId: fixture.id} : assignments[index];
      const snapshots = subtractAttributes(previous.paletteSnapshots ?? [], attributes);
      const next = {...previous, paletteSnapshots: [...snapshots, structuredClone(palette)]};
      if (index < 0) assignments.push(next); else assignments[index] = next;
    }
    return {...entry, assignments};
  });
}
