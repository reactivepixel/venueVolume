// A prototype of domain semantics, not a DMX output engine.
export function resolveValue(showDefault, override) {
  return override === undefined
    ? { value: showDefault, source: "Show default" }
    : { value: override, source: "Venue override" };
}
export function patchErrors(fixtures) {
  const issues = [];
  for (const item of fixtures) {
    if (
      !Number.isInteger(item.address) ||
      item.address < 1 ||
      item.address + item.footprint - 1 > 512
    )
      issues.push(`${item.id}: address must fit within slots 1–512`);
    if (!Number.isInteger(item.universe) || item.universe < 1)
      issues.push(`${item.id}: select a valid logical universe`);
  }
  for (let i = 0; i < fixtures.length; i++)
    for (let j = i + 1; j < fixtures.length; j++) {
      const a = fixtures[i],
        b = fixtures[j];
      if (
        a.universe === b.universe &&
        a.address <= b.address + b.footprint - 1 &&
        b.address <= a.address + a.footprint - 1
      )
        issues.push(`${a.id} overlaps ${b.id} in universe ${a.universe}`);
    }
  return issues;
}
export function advance(index, count, { armed, held, blackout, connected }) {
  return armed && !held && !blackout && connected
    ? Math.min(index + 1, count - 1)
    : index;
}
export function moveEntry(entries, index, direction) {
  const target = index + direction;
  if (target < 0 || target >= entries.length) return entries;
  const result = [...entries];
  [result[index], result[target]] = [result[target], result[index]];
  return result;
}

// Materialize demo defaults before editing so timing and MIDI move with the entry.
export function normalizeScript(entries) {
  return entries.map((entry, i) => ({
    ...entry,
    song: entry.song ?? (i === 0 ? "Walk-in" : i < 4 ? "01 · Into the blue" : "02 · Afterglow"),
    offset: entry.offset ?? (i === 0 ? 0 : i < 4 ? (i - 1) * 45 : (i - 4) * 60),
    midi: entry.midi ?? { type: "note", channel: 1, number: 60 + i },
    operatorNote: entry.operatorNote ?? (i === 0 ? "Doors open" : i === 1 ? "First sustained synth note" : "Follow stage manager"),
  }));
}

export function moveScriptEntry(entries, sourceId, targetId) {
  const from = entries.findIndex((entry) => entry.entryId === sourceId);
  const to = entries.findIndex((entry) => entry.entryId === targetId);
  if (from < 0 || to < 0 || from === to) return entries;
  const result = normalizeScript(entries);
  const [entry] = result.splice(from, 1);
  result.splice(to, 0, entry);
  return result;
}
