import test from "node:test";
import assert from "node:assert/strict";
import { advance, moveEntry, moveScriptEntry, normalizeScript, patchErrors, resolveValue } from "../src/model.js";
import { fixtureRows, screens } from "../src/catalog.js";

test("explicit zero overrides a show value; reset exposes the latest default", () => {
  assert.deepEqual(resolveValue(75, 0), { value: 0, source: "Venue override" });
  assert.deepEqual(resolveValue(80, undefined), {
    value: 80,
    source: "Show default",
  });
  assert.deepEqual(resolveValue(true, false), {
    value: false,
    source: "Venue override",
  });
});
test("patch validates boundaries, integer values and per-universe overlaps", () => {
  assert.deepEqual(patchErrors(fixtureRows), []);
  assert.match(
    patchErrors([{ id: "a", address: 509, footprint: 8, universe: 1 }])[0],
    /1–512/,
  );
  assert.match(
    patchErrors([{ id: "a", address: 1.5, footprint: 8, universe: 1 }])[0],
    /1–512/,
  );
  const a = { id: "a", address: 1, footprint: 8, universe: 1 };
  assert.match(patchErrors([a, { ...a, id: "b", address: 8 }])[0], /overlaps/);
  assert.deepEqual(patchErrors([a, { ...a, id: "b", address: 9 }]), []);
  assert.deepEqual(patchErrors([a, { ...a, id: "b", universe: 2 }]), []);
});
test("advance is guarded by arm, hold, blackout, connection and final entry", () => {
  const ready = { armed: true, held: false, blackout: false, connected: true };
  assert.equal(advance(0, 6, ready), 1);
  assert.equal(advance(5, 6, ready), 5);
  for (const state of [
    { ...ready, armed: false },
    { ...ready, held: true },
    { ...ready, blackout: true },
    { ...ready, connected: false },
  ])
    assert.equal(advance(0, 6, state), 0);
});
test("repeated cues retain separate entry identity when reordered", () => {
  const entries = [
    { entryId: "a", cue: "Q02" },
    { entryId: "b", cue: "Q03" },
    { entryId: "c", cue: "Q02" },
  ];
  assert.deepEqual(
    moveEntry(entries, 2, -1).map((e) => e.entryId),
    ["a", "c", "b"],
  );
  assert.deepEqual(
    entries.map((e) => e.entryId),
    ["a", "b", "c"],
  );
  assert.deepEqual(moveEntry(entries, 0, -1), entries);
});
test("all screens have unique routes and a defined application feature", () => {
  assert.equal(screens.length, 35);
  assert.equal(new Set(screens.map((s) => s.id)).size, 35);
  assert.ok(screens.every((s) => /^F(0[1-9]|1[0-5])$/.test(s.feature)));
});
test("slot drag inserts rather than swaps and preserves per-entry defaults and identity", () => {
  const entries = [
    { entryId: "a", id: "Q02" },
    { entryId: "b", id: "Q03" },
    { entryId: "c", id: "Q02" },
  ];
  const before = normalizeScript(entries);
  const moved = moveScriptEntry(entries, "a", "c");
  assert.deepEqual(moved.map((entry) => entry.entryId), ["b", "c", "a"]);
  assert.deepEqual(moved[2], before[0]);
  assert.deepEqual(moved[0], before[1]);
  assert.deepEqual(moveScriptEntry(moved, "a", "b").map((entry) => entry.entryId), ["a", "b", "c"]);
  assert.equal(entries[0].song, undefined);
});
test("invalid and same-slot reorders are no-ops", () => {
  const entries = [{ entryId: "a" }, { entryId: "b" }];
  assert.equal(moveScriptEntry(entries, "missing", "b"), entries);
  assert.equal(moveScriptEntry(entries, "a", "missing"), entries);
  assert.equal(moveScriptEntry(entries, "a", "a"), entries);
});
