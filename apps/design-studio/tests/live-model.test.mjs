import test from "node:test";
import assert from "node:assert/strict";
import { fixtureRows, presetRows, cueRows } from "../src/catalog.js";
import {
  createRun,
  makeSnapshot,
  outputValue,
  reduceRun,
  midiMatches,
  scriptSegments,
} from "../src/live-model.js";
const data = {
  fixtures: fixtureRows,
  presets: presetRows,
  script: cueRows.map((e, i) => ({ ...e, entryId: `entry-${i}` })),
  intensity: 75,
  venueOverrides: { Glasshouse: 60 },
};
const snapshot = makeSnapshot(data, "Glasshouse");
const armed = () => reduceRun(createRun(snapshot), { type: "arm" });
test("timeline song segments preserve script order including repeated song labels", () => {
  const entries = [
    { entryId: "a", song: "One" },
    { entryId: "b", song: "Two" },
    { entryId: "c", song: "One" },
  ];
  assert.deepEqual(scriptSegments(entries).flatMap((segment) => segment.entries), entries);
  assert.equal(scriptSegments(entries).length, 3);
});
test("Back and Next step through script; Hold/Play gates input without jumping or queuing", () => {
  let run = reduceRun(armed(), { type: "midi-enabled", value: true });
  run = reduceRun(run, { type: "next" });
  run = reduceRun(run, { type: "next" });
  run = reduceRun(run, { type: "next" });
  run = reduceRun(run, { type: "back" });
  assert.equal(run.activeId, "entry-1");
  assert.equal(run.hits["entry-2"], undefined);
  assert.equal(run.history.at(-1).source, "Back");
  const look = run.activeValues;
  run = reduceRun(run, { type: "hold" });
  for (const action of [{ type: "next" }, { type: "back" }, { type: "midi", bytes: [0x90, 62, 100] }])
    run = reduceRun(run, action);
  assert.equal(run.activeId, "entry-1");
  assert.deepEqual(run.activeValues, look);
  run = reduceRun(run, { type: "hold" });
  assert.equal(run.activeId, "entry-1");
  run = reduceRun(run, { type: "midi", bytes: [0x90, 62, 100] });
  assert.equal(run.activeId, "entry-2");
  for (let i = 0; i < 10; i++) run = reduceRun(run, { type: "next" });
  assert.equal(run.activeId, snapshot.script.at(-1).entryId);
  run = reduceRun(run, { type: "house" });
  assert.equal(run.activeId, snapshot.houseEntryId);
  assert.equal(run.history.at(-1).source, "House");
  run = reduceRun(run, { type: "back" });
  assert.equal(run.activeId, "entry-0");
  run = reduceRun(run, { type: "midi", bytes: [0x90, 61, 100] });
  assert.equal(run.activeId, "entry-1");
  const missingHouse = reduceRun({ ...run, snapshot: { ...snapshot, houseEntryId: null } }, { type: "house" });
  assert.equal(missingHouse.activeId, run.activeId);
});
test("inspection is separate from activation; first GO calls the first entry", () => {
  const run = armed();
  assert.equal(run.activeId, null);
  assert.deepEqual(run.hits, {});
  const next = reduceRun(run, { type: "go", at: 100 });
  assert.equal(next.activeId, "entry-0");
  assert.equal(next.history.length, 1);
});
test("MIDI requires armed/enabled input, ignores Note Off and zero velocity, and debounces fired entries", () => {
  assert.equal(
    midiMatches({ type: "note", channel: 1, number: 60 }, [0x80, 60, 127]),
    false,
  );
  assert.equal(
    midiMatches({ type: "note", channel: 1, number: 60 }, [0x90, 60, 0]),
    false,
  );
  assert.equal(
    midiMatches({ type: "note", channel: 1, number: 60 }, [0x91, 60, 127]),
    false,
  );
  let run = reduceRun(armed(), { type: "midi-enabled", value: true });
  run = reduceRun(run, { type: "midi", bytes: [0x90, 61, 100], at: 200 });
  assert.equal(run.activeId, "entry-1");
  assert.equal(run.hits["entry-0"], undefined);
  run = reduceRun(run, { type: "midi", bytes: [0x90, 61, 100], at: 201 });
  assert.equal(run.history.length, 1);
  run = reduceRun(run, { type: "hold" });
  run = reduceRun(run, { type: "midi", bytes: [0x90, 62, 100] });
  assert.equal(run.activeId, "entry-1");
});
test("restarting a song retains historical events and re-enables subsequent MIDI cues", () => {
  let run = reduceRun(armed(), { type: "midi-enabled", value: true });
  for (const number of [60, 61, 62, 63])
    run = reduceRun(run, { type: "midi", bytes: [0x90, number, 100] });
  run = reduceRun(run, { type: "restart", entryId: "entry-1" });
  assert.equal(run.pass, 2);
  assert.ok(run.hits["entry-0"]);
  assert.ok(run.hits["entry-1"]);
  assert.equal(run.hits["entry-2"], undefined);
  assert.equal(run.history.length, 5);
  run = reduceRun(run, { type: "midi", bytes: [0x90, 62, 100] });
  assert.equal(run.activeId, "entry-2");
  assert.equal(run.history.at(-1).pass, 2);
});
test("fixture adjustments preserve relative nudge, override cues, respect masters and release", () => {
  let run = reduceRun(armed(), { type: "go" });
  run = reduceRun(run, {
    type: "programmer",
    ids: ["FX-001", "FX-002"],
    values: { intensity: 0, color: "#ff0000" },
  });
  run = reduceRun(run, { type: "go" });
  assert.equal(outputValue(run, fixtureRows[0]).intensity, 0);
  assert.equal(outputValue(run, fixtureRows[2]).intensity, 60);
  run = reduceRun(run, {
    type: "programmer",
    ids: ["FX-001", "FX-003"],
    nudge: 5,
  });
  assert.equal(outputValue(run, fixtureRows[0]).intensity, 5);
  assert.equal(outputValue(run, fixtureRows[2]).intensity, 65);
  run = reduceRun(run, {
    type: "programmer",
    ids: ["FX-001"],
    values: { intensity: 80 },
  });
  run = reduceRun(run, { type: "master", value: 50 });
  run = reduceRun(run, { type: "group", role: "Upstage wash", value: 50 });
  assert.equal(outputValue(run, fixtureRows[0]).effective, 20);
  run = reduceRun(run, { type: "blackout" });
  assert.equal(outputValue(run, fixtureRows[0]).effective, 0);
  run = reduceRun(run, { type: "blackout" });
  assert.equal(outputValue(run, fixtureRows[0]).effective, 20);
  run = reduceRun(run, { type: "release", ids: ["FX-001"] });
  assert.equal(outputValue(run, fixtureRows[0]).intensity, 60);
  assert.ok(run.programmer["FX-002"]);
});
test("hot edits update future calls without overwriting the active look or manual values", () => {
  let run = reduceRun(armed(), { type: "call", entryId: "entry-1" });
  const edited = makeSnapshot(
    { ...data, venueOverrides: { Glasshouse: 20 } },
    "Glasshouse",
  );
  run = reduceRun(run, { type: "apply-draft", snapshot: edited });
  assert.equal(outputValue(run, fixtureRows[0]).intensity, 60);
  run = reduceRun(run, { type: "call", entryId: "entry-1" });
  assert.equal(outputValue(run, fixtureRows[0]).intensity, 20);
  const changedFixtures = { ...edited, fixtures: edited.fixtures.slice(1) };
  run = reduceRun(run, { type: "apply-draft", snapshot: changedFixtures });
  assert.equal(run.snapshot.fixtures.length, 8);
  assert.match(run.lastMessage, /Disarm/);
});
test("connection loss disables input and marks actual output unknown", () => {
  let run = reduceRun(armed(), { type: "go" });
  run = reduceRun(run, { type: "connection", value: false });
  assert.equal(run.armed, false);
  assert.equal(run.midiEnabled, false);
  assert.equal(outputValue(run, fixtureRows[0]).unknown, true);
  run = reduceRun(run, { type: "go" });
  assert.equal(run.activeId, "entry-0");
  run = reduceRun(run, { type: "connection", value: true });
  assert.equal(run.armed, false);
});
