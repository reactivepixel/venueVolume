import * as THREE from "three";

// Keep the complete room in the scene and label its exterior wall faces so
// each isometric camera can hide only the two walls nearest to it.
export function separateExteriorWalls(roomRoot, manifest) {
  const { min, max } = manifest.bounds || {};
  if (!Array.isArray(min) || !Array.isArray(max)) return {};
  const sides = ["+x", "-x", "+z", "-z"];
  const counts = Object.fromEntries(sides.map((side) => [side, 0]));
  const tolerance = 0.38;
  const vertices = [new THREE.Vector3(), new THREE.Vector3(), new THREE.Vector3()];
  const meshes = [];
  roomRoot.updateMatrixWorld(true);
  roomRoot.traverse((node) => {
    if (node.isMesh && node.geometry?.attributes.position && node.userData.venuePart !== "ceiling") meshes.push(node);
  });
  for (const mesh of meshes) {
    const source = mesh.geometry;
    const position = source.attributes.position;
    const count = source.index?.count ?? position.count;
    if (count % 3) continue;
    const groups = source.groups.length ? source.groups : [{ start: 0, count, materialIndex: 0 }];
    const indices = Object.fromEntries(["body", ...sides].map((key) => [key, []]));
    const outputGroups = Object.fromEntries(["body", ...sides].map((key) => [key, []]));
    for (const group of groups) {
      const starts = Object.fromEntries(Object.keys(indices).map((key) => [key, indices[key].length]));
      for (let i = group.start; i < group.start + group.count; i += 3) {
        const triangle = [0, 1, 2].map((offset) => source.index?.getX(i + offset) ?? i + offset);
        triangle.forEach((index, offset) => vertices[offset].fromBufferAttribute(position, index).applyMatrix4(mesh.matrixWorld));
        const xs = vertices.map((v) => v.x), ys = vertices.map((v) => v.y), zs = vertices.map((v) => v.z);
        let side = "body";
        // A vertical face near the room envelope is part of an exterior wall.
        // Requiring vertical extent keeps floor/ceiling strips and furnishings intact.
        if (Math.max(...ys) - Math.min(...ys) > 0.05 && Math.max(...ys) > min[1] + 0.2) {
          const candidates = [
            ["+x", Math.max(...xs.map((x) => Math.abs(x - max[0]))), Math.max(...xs) - Math.min(...xs)],
            ["-x", Math.max(...xs.map((x) => Math.abs(x - min[0]))), Math.max(...xs) - Math.min(...xs)],
            ["+z", Math.max(...zs.map((z) => Math.abs(z - max[2]))), Math.max(...zs) - Math.min(...zs)],
            ["-z", Math.max(...zs.map((z) => Math.abs(z - min[2]))), Math.max(...zs) - Math.min(...zs)],
          ].filter(([, distance]) => distance <= tolerance);
          candidates.sort((a, b) => a[2] - b[2] || a[1] - b[1]);
          if (candidates.length) side = candidates[0][0];
        }
        indices[side].push(...triangle);
      }
      for (const key of Object.keys(indices)) {
        if (indices[key].length > starts[key]) outputGroups[key].push({
          start: starts[key], count: indices[key].length - starts[key], materialIndex: group.materialIndex,
        });
      }
    }
    const populated = sides.filter((side) => indices[side].length);
    if (!populated.length) continue;
    for (const side of populated) counts[side] += indices[side].length / 3;
    function geometryFor(key) {
      const geometry = source.clone();
      geometry.setIndex(indices[key]);
      geometry.clearGroups();
      for (const group of outputGroups[key]) geometry.addGroup(group.start, group.count, group.materialIndex);
      return geometry;
    }
    if (!indices.body.length && populated.length === 1) {
      mesh.userData = { ...mesh.userData, venuePart: "wall", venueSide: populated[0] };
      continue;
    }
    for (const side of populated) {
      const wall = mesh.clone(false);
      wall.name = `wall${side}:${mesh.name}`;
      wall.userData = { ...mesh.userData, venuePart: "wall", venueSide: side };
      wall.geometry = geometryFor(side);
      mesh.parent.add(wall);
    }
    if (indices.body.length) mesh.geometry = geometryFor("body");
    else { mesh.removeFromParent(); source.dispose(); }
  }
  return counts;
}
