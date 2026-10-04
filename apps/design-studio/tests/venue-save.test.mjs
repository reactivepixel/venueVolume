import test from "node:test";
import assert from "node:assert/strict";
import {
  readVenueSave,
  readScannedMesh,
  sha256,
  MAX_SAVE_BYTES,
} from "../src/venue-save.js";
const fixture = () => ({
  id: "10000000-0000-4000-8000-000000000001",
  name: "Light",
  position: { x: 1, y: 2, z: -3 },
  orientation: { x: 0, y: 0, z: 0, w: 1 },
  scale: { x: 1, y: 1, z: 1 },
  universe: 1,
  startAddress: 1,
  channels: [0, 0, 0, 0, 128, 128],
});
const mesh = {
  schemaVersion: 1,
  chunks: [
    {
      vertices: [
        { x: 0, y: 0, z: 0 },
        { x: 1, y: 0, z: 0 },
        { x: 0, y: 0, z: 1 },
      ],
      triangles: [0, 1, 2],
    },
  ],
};
async function save() {
  const asset = Buffer.from(JSON.stringify(mesh));
  return {
    format: "com.venuevolume.save",
    schemaVersion: 1,
    room: {
      manifest: {
        schemaVersion: 1,
        id: "room",
        version: "version",
        units: "meters",
        upAxis: "Y",
        forwardAxis: "-Z",
        asset: {
          file: "environment.mesh.json",
          bytes: asset.length,
          sha256: await sha256(asset),
        },
      },
    },
    setup: {
      schemaVersion: 1,
      id: "20000000-0000-4000-8000-000000000001",
      name: "My rig",
      roomID: "room-version",
      placements: {
        schemaVersion: 1,
        environmentID: "room",
        environmentVersion: "version",
        fixtures: [fixture()],
      },
    },
    asset: asset.toString("base64"),
  };
}
const file = (s) => new File([JSON.stringify(s)], "test.venuevolume");
test("reads actual portable save structure and verifies embedded geometry", async () => {
  const s = await save(),
    result = await readVenueSave(file(s));
  assert.deepEqual(result.save, s);
  assert.deepEqual(readScannedMesh(result.asset), mesh);
});
test("rejects empty, oversized, corrupt and unsupported saves", async () => {
  await assert.rejects(readVenueSave(new File([], "empty")), /350 MB/);
  await assert.rejects(readVenueSave({ size: MAX_SAVE_BYTES + 1 }), /350 MB/);
  await assert.rejects(
    readVenueSave(new File(["broken"], "bad")),
    /valid Venue/,
  );
  const s = await save();
  s.schemaVersion = 2;
  await assert.rejects(readVenueSave(file(s)), /Unsupported/);
});
test("rejects a wrong room association, checksum or byte count", async () => {
  for (const mutate of [
    (s) => (s.setup.roomID = "wrong"),
    (s) => (s.setup.placements.environmentVersion = "wrong"),
    (s) => (s.room.manifest.asset.sha256 = "0".repeat(64)),
    (s) => s.room.manifest.asset.bytes++,
  ]) {
    const s = await save();
    mutate(s);
    await assert.rejects(readVenueSave(file(s)));
  }
});
test("rejects duplicate IDs and invalid transform/channel data", async () => {
  for (const mutate of [
    (s) => s.setup.placements.fixtures.push(fixture()),
    (s) => (s.setup.placements.fixtures[0].orientation.w = 2),
    (s) => (s.setup.placements.fixtures[0].scale.x = -1),
    (s) => (s.setup.placements.fixtures[0].position.y = null),
    (s) => (s.setup.placements.fixtures[0].channels[0] = 256),
    (s) => (s.setup.placements.fixtures[0].startAddress = 512),
  ]) {
    const s = await save();
    mutate(s);
    await assert.rejects(readVenueSave(file(s)), /fixture/);
  }
});
test("native scanned mesh rejects invalid indices and nonfinite vertices", () => {
  for (const mutate of [
    (m) => (m.chunks[0].triangles[0] = 9),
    (m) => (m.chunks[0].vertices[0].x = null),
    (m) => m.chunks[0].triangles.push(0),
  ]) {
    const m = structuredClone(mesh);
    mutate(m);
    assert.throws(
      () => readScannedMesh(Buffer.from(JSON.stringify(m))),
      /triangles/,
    );
  }
});
