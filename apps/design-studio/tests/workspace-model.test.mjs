import test from "node:test";
import assert from "node:assert/strict";
import {
  emptyWorkspace,
  transition,
  inventoryIds,
  baseChanges,
  readiness,
} from "../src/workspace-model.js";
const venues = [
  {
    id: "v1",
    name: "Room",
    assetUrl: "/scan.ply",
    status: "ready",
    setupStatus: "configured",
  },
];
function fixture() {
  let state = emptyWorkspace();
  const act = (a) => (state = transition(state, a, venues));
  for (const id of ["a", "b", "c"])
    act({ type: "add-unit", id, name: id, model: "Wash", footprint: 8 });
  return { act, state: () => state };
}
test("Only imported scans can become layouts; multiple Load Outs remain isolated", () => {
  const f = fixture();
  assert.throws(() =>
    transition(
      f.state(),
      { type: "add-loadout", id: "x", name: "Blank", venueId: "raw" },
      venues,
    ),
  );
  assert.throws(
    () =>
      transition(
        f.state(),
        { type: "add-loadout", id: "x", name: "Early", venueId: "v1" },
        [{ ...venues[0], setupStatus: "needs_setup" }],
      ),
    /imported/,
  );
  for (const id of ["one", "two"])
    f.act({ type: "add-loadout", id, name: id, venueId: "v1" });
  f.act({ type: "loadout-inventory", id: "one", unitIds: ["a", "a"] });
  f.act({
    type: "place",
    id: "one",
    unitId: "a",
    position: { x: 1, y: 2, z: 3, yaw: 0 },
  });
  assert.deepEqual(inventoryIds(f.state().loadouts[0]), ["a"]);
  assert.deepEqual(f.state().loadouts[1].placements, {});
});
test("Tour stops pin base inventory; adoption retains removed units as local additions", () => {
  const f = fixture();
  f.act({ type: "add-tour", id: "t", name: "Tour" });
  f.act({ type: "tour-base", id: "t", unitIds: ["a"] });
  for (const id of ["s1", "s2"])
    f.act({
      type: "add-stop",
      id,
      tourId: "t",
      loadoutId: `l${id}`,
      name: id,
      venueId: "v1",
    });
  f.act({ type: "loadout-inventory", id: "ls1", unitIds: ["a", "c"] });
  f.act({
    type: "place",
    id: "ls1",
    unitId: "a",
    position: { x: 1, y: 2, z: 3, yaw: 0 },
  });
  f.act({ type: "tour-base", id: "t", unitIds: ["b"] });
  assert.deepEqual(baseChanges(f.state(), f.state().loadouts[0]), {
    added: ["b"],
    removed: ["a"],
  });
  f.act({ type: "adopt-base", id: "ls1" });
  assert.deepEqual(inventoryIds(f.state().loadouts[0]), ["b", "c", "a"]);
  assert.equal(f.state().loadouts[0].placements.a.x, 1);
  assert.deepEqual(inventoryIds(f.state().loadouts[1]), ["a"]);
});
test("Referenced units cannot be deleted; return to inventory preserves patch", () => {
  const f = fixture();
  f.act({ type: "add-loadout", id: "l", name: "Load Out", venueId: "v1" });
  f.act({ type: "loadout-inventory", id: "l", unitIds: ["a"] });
  assert.throws(() => f.act({ type: "remove-unit", id: "a" }), /used/);
  f.act({
    type: "place",
    id: "l",
    unitId: "a",
    position: { x: 0, y: 0, z: 0, yaw: 0 },
  });
  f.act({ type: "patch", id: "l", unitId: "a", universe: 1, address: 1 });
  assert.throws(
    () => f.act({ type: "loadout-inventory", id: "l", unitIds: [] }),
    /Return placed/,
  );
  f.act({ type: "unplace", id: "l", unitId: "a" });
  assert.equal(f.state().loadouts[0].patch.a.address, 1);
  f.act({ type: "loadout-inventory", id: "l", unitIds: [] });
  f.act({ type: "remove-unit", id: "a" });
  assert.equal(f.state().units.length, 2);
});
test("Readiness covers patch overlap, placement and scan review", () => {
  const f = fixture();
  f.act({ type: "add-loadout", id: "l", name: "Plan", venueId: "v1" });
  f.act({ type: "loadout-inventory", id: "l", unitIds: ["a", "b"] });
  for (const unitId of ["a", "b"]) {
    f.act({
      type: "place",
      id: "l",
      unitId,
      position: { x: 0, y: 0, z: 0, yaw: 0 },
    });
    f.act({ type: "patch", id: "l", unitId, universe: 1, address: 1 });
  }
  assert.ok(
    readiness(f.state(), f.state().loadouts[0]).some((i) =>
      i.includes("overlaps"),
    ),
  );
  f.act({ type: "patch", id: "l", unitId: "b", universe: 1, address: 9 });
  f.act({ type: "review-scan", id: "l", reviewed: true });
  assert.deepEqual(readiness(f.state(), f.state().loadouts[0]), []);
  assert.throws(
    () =>
      f.act({ type: "patch", id: "l", unitId: "a", universe: 1, address: 512 }),
    /fits/,
  );
});
test("Duplicating a plan preserves physical identity and isolates edits", () => {
  const f = fixture();
  f.act({ type: "add-loadout", id: "l", name: "Plan", venueId: "v1" });
  f.act({ type: "loadout-inventory", id: "l", unitIds: ["a"] });
  f.act({ type: "copy-loadout", id: "l", newId: "copy", name: "Alternate" });
  f.act({
    type: "place",
    id: "copy",
    unitId: "a",
    position: { x: 5, y: 0, z: 0, yaw: 0 },
  });
  assert.equal(f.state().units.length, 3);
  assert.equal(f.state().loadouts[1].venueId, "v1");
  assert.equal(f.state().loadouts[1].tourId, "");
  assert.deepEqual(f.state().loadouts[0].placements, {});
});
test("Invalid references do not mutate state", () => {
  const f = fixture();
  f.act({ type: "add-loadout", id: "l", name: "Plan", venueId: "v1" });
  const original = structuredClone(f.state());
  assert.throws(() =>
    f.act({ type: "loadout-inventory", id: "l", unitIds: ["missing"] }),
  );
  assert.throws(() =>
    f.act({
      type: "place",
      id: "l",
      unitId: "a",
      position: { x: NaN, y: 0, z: 0, yaw: 0 },
    }),
  );
  assert.deepEqual(f.state(), original);
});
