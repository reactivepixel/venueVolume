import test from "node:test";
import assert from "node:assert/strict";
import * as THREE from "three";
import { separateCeiling } from "../src/venue-ceiling.js";

const triangles = (root) => {
  let count = 0;
  root.traverse((o) => {
    if (o.isMesh)
      count +=
        (o.geometry.index?.count ?? o.geometry.attributes.position.count) / 3;
  });
  return count;
};
test("separates top faces from walls while preserving all triangles and material groups", () => {
  const room = new THREE.Group();
  const material = new Array(6)
    .fill(null)
    .map(() => new THREE.MeshStandardMaterial());
  const mesh = new THREE.Mesh(new THREE.BoxGeometry(5, 3, 5), material);
  mesh.position.y = 1.5;
  room.add(mesh);
  const before = triangles(room);
  const hidden = separateCeiling(room, { bounds: { max: [5, 3, 5] } });
  assert.equal(hidden, 2);
  assert.equal(triangles(room), before);
  const ceiling = room.children.find((o) => o.userData.venuePart === "ceiling");
  assert.ok(ceiling);
  assert.equal(triangles(ceiling), 2);
  assert.equal(mesh.geometry.groups.length, 5);
  assert.equal(ceiling.geometry.groups.length, 1);
  assert.equal(ceiling.geometry.groups[0].materialIndex, 2);
});
test("leaves rooms without a top surface intact", () => {
  const room = new THREE.Group();
  const floor = new THREE.Mesh(
    new THREE.PlaneGeometry(3, 3),
    new THREE.MeshStandardMaterial(),
  );
  floor.rotation.x = -Math.PI / 2;
  room.add(floor);
  assert.equal(separateCeiling(room, { bounds: { max: [3, 3, 3] } }), 0);
  assert.equal(room.children.length, 1);
});
