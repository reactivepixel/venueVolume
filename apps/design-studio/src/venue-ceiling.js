import * as THREE from "three";

// Native manifests describe a room envelope but do not label roof polygons.
// Split only faces confined to the upper 23 cm into independently hideable
// meshes; walls and fixtures keep their geometry, transforms and materials.
export function separateCeiling(roomRoot, manifest) {
  if (!Number.isFinite(manifest.bounds?.max?.[1])) return 0;
  const cutoff = manifest.bounds.max[1] - 0.23;
  const meshes = [];
  roomRoot.updateMatrixWorld(true);
  roomRoot.traverse((node) => {
    if (node.isMesh && node.geometry?.attributes.position) meshes.push(node);
  });
  let triangles = 0;
  const a = new THREE.Vector3(),
    b = new THREE.Vector3(),
    c = new THREE.Vector3();
  for (const mesh of meshes) {
    const source = mesh.geometry;
    const position = source.attributes.position;
    const count = source.index?.count ?? position.count;
    if (count % 3) continue;
    const groups = source.groups.length
      ? source.groups
      : [{ start: 0, count, materialIndex: 0 }];
    const body = [],
      ceiling = [],
      bodyGroups = [],
      ceilingGroups = [];
    for (const group of groups) {
      const bodyStart = body.length,
        ceilingStart = ceiling.length;
      for (let i = group.start; i < group.start + group.count; i += 3) {
        const index = [0, 1, 2].map(
          (offset) => source.index?.getX(i + offset) ?? i + offset,
        );
        a.fromBufferAttribute(position, index[0]).applyMatrix4(
          mesh.matrixWorld,
        );
        b.fromBufferAttribute(position, index[1]).applyMatrix4(
          mesh.matrixWorld,
        );
        c.fromBufferAttribute(position, index[2]).applyMatrix4(
          mesh.matrixWorld,
        );
        (Math.min(a.y, b.y, c.y) >= cutoff ? ceiling : body).push(...index);
      }
      if (body.length > bodyStart)
        bodyGroups.push({
          start: bodyStart,
          count: body.length - bodyStart,
          materialIndex: group.materialIndex,
        });
      if (ceiling.length > ceilingStart)
        ceilingGroups.push({
          start: ceilingStart,
          count: ceiling.length - ceilingStart,
          materialIndex: group.materialIndex,
        });
    }
    if (!ceiling.length) continue;
    triangles += ceiling.length / 3;
    if (!body.length) {
      mesh.userData = { ...mesh.userData, venuePart: "ceiling" };
      continue;
    }
    function part(indices, groups) {
      const geometry = source.clone();
      geometry.setIndex(indices);
      geometry.clearGroups();
      for (const group of groups)
        geometry.addGroup(group.start, group.count, group.materialIndex);
      return geometry;
    }
    const roof = mesh.clone(false);
    roof.name = `ceiling:${mesh.name}`;
    roof.userData = { ...mesh.userData, venuePart: "ceiling" };
    roof.geometry = part(ceiling, ceilingGroups);
    mesh.geometry = part(body, bodyGroups);
    mesh.parent.add(roof);
  }
  return triangles;
}
