import test from "node:test";
import assert from "node:assert/strict";
import * as THREE from "three";
import { separateExteriorWalls } from "../src/venue-walls.js";

test("labels four exterior walls and preserves every triangle and material group", () => {
  const room = new THREE.Group();
  const materials = Array.from({ length: 6 }, () => new THREE.MeshStandardMaterial());
  const mesh = new THREE.Mesh(new THREE.BoxGeometry(5, 3, 5), materials);
  mesh.position.set(2.5, 1.5, 2.5);
  room.add(mesh);
  const counts = separateExteriorWalls(room, { bounds: { min: [0, 0, 0], max: [5, 3, 5] } });
  assert.deepEqual(counts, { "+x": 2, "-x": 2, "+z": 2, "-z": 2 });
  let triangles = 0;
  const sides = new Set();
  room.traverse((node) => {
    if (!node.isMesh) return;
    triangles += node.geometry.index.count / 3;
    if (node.userData.venueSide) {
      sides.add(node.userData.venueSide);
      assert.equal(node.geometry.groups.length, 1);
    }
  });
  assert.equal(triangles, 12);
  assert.deepEqual(sides, new Set(["+x", "-x", "+z", "-z"]));
});

test("unbounded scans remain complete", () => {
  const room = new THREE.Group();
  room.add(new THREE.Mesh(new THREE.BoxGeometry(1, 1, 1)));
  assert.deepEqual(separateExteriorWalls(room, {}), {});
  assert.equal(room.children.length, 1);
});
