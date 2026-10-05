import * as THREE from "three";
import { USDLoader } from "three/addons/loaders/USDLoader.js";
import { GLTFExporter } from "three/addons/exporters/GLTFExporter.js";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import { unzipSync } from "fflate";
import catalog from "../../../assets/fixtures/runtime-catalog.json";
import {
  readVenueSave,
  readScannedMesh,
  sha256,
  MAX_SAVE_BYTES,
} from "./venue-save.js";
import { separateCeiling } from "./venue-ceiling.js";
import { separateExteriorWalls } from "./venue-walls.js";

// Axes are room-local: right +X, up +Y, front −Z. All eight cube corners.
export const ISOMETRIC_VIEWS = [1, -1].flatMap((y) =>
  [-1, 1].flatMap((z) =>
    [1, -1].map((x) => ({
      id: `${y > 0 ? "upper" : "lower"}-${z < 0 ? "front" : "rear"}-${x > 0 ? "right" : "left"}`,
      direction: [x, y, z],
    })),
  ),
);

export function disposeScene(root) {
  const geometries = new Set(),
    materials = new Set(),
    textures = new Set();
  root?.traverse((o) => {
    if (o.geometry) geometries.add(o.geometry);
    for (const m of o.material
      ? Array.isArray(o.material)
        ? o.material
        : [o.material]
      : []) {
      materials.add(m);
      Object.values(m).forEach((v) => {
        if (v?.isTexture) textures.add(v);
      });
    }
  });
  geometries.forEach((g) => g.dispose());
  materials.forEach((m) => m.dispose());
  textures.forEach((t) => t.dispose());
}

async function parseUSD(bytes) {
  // USDZ is a self-contained, uncompressed archive. Preflight with the patched
  // ZIP reader; reject ZIP64/compressed packages and external resource requests.
  let total = 0,
    count = 0;
  // Reject ZIP64 using the actual end record, not signatures inside asset data.
  const tail = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const earliest = Math.max(0, bytes.length - 65557);
  let end = bytes.length - 22;
  for (; end >= earliest; end--) {
    if (
      tail.getUint32(end, true) === 0x06054b50 &&
      end + 22 + tail.getUint16(end + 20, true) === bytes.length
    )
      break;
  }
  if (end < earliest) throw new Error("The USDZ archive is invalid.");
  if (
    (end >= 20 && tail.getUint32(end - 20, true) === 0x07064b50) ||
    tail.getUint16(end + 10, true) === 0xffff ||
    tail.getUint32(end + 16, true) === 0xffffffff
  ) {
    throw new Error("ZIP64 USDZ packages are not supported.");
  }
  unzipSync(bytes, {
    filter: (f) => {
      total += f.originalSize;
      count++;
      if (
        f.compression !== 0 ||
        total > 350_000_000 ||
        count > 4096 ||
        !Number.isSafeInteger(total)
      )
        throw new Error("Unsupported or oversized USDZ archive.");
      return false;
    },
  });
  if (!count) throw new Error("The USDZ archive is empty.");
  const manager = new THREE.LoadingManager();
  manager.setURLModifier((url) => {
    if (!url.startsWith("blob:"))
      throw new Error(
        "The USDZ references external textures. Export a self-contained venue asset.",
      );
    return url;
  });
  const group = await new Promise((resolve, reject) => {
    new USDLoader(manager).parse(
      bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength),
      "",
      resolve,
      reject,
    );
  });
  let meshes = 0;
  group.traverse((o) => {
    if (o.isMesh) meshes++;
  });
  if (!meshes) {
    disposeScene(group);
    throw new Error("No renderable meshes were found in the USDZ.");
  }
  return group;
}

export function poseFixture(template, descriptor, fixture) {
  const root = new THREE.Group();
  root.name = fixture.name;
  root.userData = {
    kind: "fixture",
    fixtureID: fixture.id,
    fixtureName: fixture.name,
    assetID: fixture.assetID ?? null,
    universe: fixture.universe,
    startAddress: fixture.startAddress,
    channels: fixture.channels,
  };
  root.add(template);
  if (descriptor) {
    const source = template.getObjectByName("Fixture");
    if (!source)
      throw new Error(`${descriptor.name}: model has no Fixture root.`);
    const members = new Map(
      descriptor.joints.map((j) => [
        j.id,
        j.members.map((path) => {
          const part = path
            .split("/")
            .slice(2)
            .reduce(
              (parent, name) => parent?.children.find((c) => c.name === name),
              source,
            );
          if (!part)
            throw new Error(`${descriptor.name}: missing model part ${path}.`);
          return part;
        }),
      ]),
    );
    const joints = new Map();
    for (const j of descriptor.joints) {
      const joint = new THREE.Group();
      joint.name = `vv-joint:${j.id}`;
      joint.userData.jointID = j.id;
      root.add(joint);
      joint.position.fromArray(j.pivot);
      root.updateMatrixWorld(true);
      if (j.parent) joints.get(j.parent).attach(joint);
      members.get(j.id).forEach((part) => joint.attach(part));
      joints.set(j.id, joint);
    }
    const channels = [...fixture.channels];
    if (fixture.aimOverride) {
      channels[4] = fixture.aimOverride.pan;
      channels[5] = fixture.aimOverride.tilt;
    }
    for (const j of descriptor.joints) {
      const byte =
        fixture.jointOverrides?.[j.id] ??
        channels[j.channel] ??
        (j.continuous ? 0 : 128);
      // A save contains rotational speed, not elapsed phase, for continuous joints.
      const degrees = j.continuous ? 0 : ((byte - 128) / 255) * j.travel;
      joints
        .get(j.id)
        .quaternion.setFromAxisAngle(
          new THREE.Vector3(...j.axis).normalize(),
          (degrees * Math.PI) / 180,
        );
    }
  }
  root.position.copy(fixture.position);
  root.quaternion.copy(fixture.orientation);
  root.scale.copy(fixture.scale);
  return root;
}

export async function sceneFromSave(file, progress = () => {}) {
  progress("Checking the venue save…");
  const { save, asset } = await readVenueSave(file);
  const manifest = save.room.manifest;
  const scene = new THREE.Group();
  scene.name = save.setup.name;
  scene.userData = {
    format: "com.venuevolume.web-scene",
    version: 1,
    setupID: save.setup.id,
    roomID: save.setup.roomID,
    roomName: manifest.title || manifest.id,
    sourceModified: save.setup.modified,
    units: "meters",
    upAxis: "Y",
    forwardAxis: "-Z",
    assetSHA256: manifest.asset.sha256,
    fixtureCount: save.setup.placements.fixtures.length,
    spawn: manifest.spawn
      ? {
          position: manifest.spawn.position,
          yaw: manifest.spawn.yaw,
          bounds: manifest.bounds,
        }
      : null,
    notes:
      "Static placement snapshot. Continuous joints use their rest phase. Live lighting and cues are not baked.",
  };
  const templates = new Map();
  try {
    progress("Loading venue geometry…");
    let room;
    if (manifest.asset.file === "environment.usdz")
      room = await parseUSD(asset);
    else {
      room = new THREE.Group();
      for (const chunk of readScannedMesh(asset).chunks) {
        const g = new THREE.BufferGeometry();
        g.setAttribute(
          "position",
          new THREE.Float32BufferAttribute(
            chunk.vertices.flatMap((v) => [v.x, v.y, v.z]),
            3,
          ),
        );
        g.setIndex(chunk.triangles);
        g.computeVertexNormals();
        room.add(
          new THREE.Mesh(
            g,
            new THREE.MeshStandardMaterial({
              color: 0xa7b2c0,
              roughness: 0.9,
              side: THREE.DoubleSide,
            }),
          ),
        );
      }
    }
    const roomRoot = new THREE.Group();
    roomRoot.name = "Venue";
    roomRoot.userData.kind = "venue";
    roomRoot.add(room);
    if (manifest.assetTranslation)
      roomRoot.position.fromArray(manifest.assetTranslation);
    scene.add(roomRoot);
    scene.userData.ceilingTriangles = separateCeiling(roomRoot, manifest);
    scene.userData.wallTrianglesBySide = separateExteriorWalls(roomRoot, manifest);
    let index = 0;
    for (const f of save.setup.placements.fixtures) {
      progress(
        `Loading fixture ${++index} of ${save.setup.placements.fixtures.length}: ${f.name}…`,
      );
      const descriptor = catalog.find((a) => a.id === f.assetID);
      if (f.assetID && !descriptor)
        throw new Error(
          `Fixture model “${f.assetID}” is unavailable. Update the fixture library before exporting.`,
        );
      let template;
      if (descriptor) {
        if (!templates.has(descriptor.id)) {
          const response = await fetch(
            `/fixture-models/${encodeURI(descriptor.id)}.usdz`,
          );
          if (!response.ok)
            throw new Error(
              `Could not load ${descriptor.name}. Try importing again when its model is available.`,
            );
          const bytes = new Uint8Array(await response.arrayBuffer());
          if ((await sha256(bytes)) !== descriptor.sha256)
            throw new Error(
              `${descriptor.name}: fixture model checksum mismatch.`,
            );
          templates.set(descriptor.id, await parseUSD(bytes));
        }
        template = templates.get(descriptor.id).clone(true);
      } else {
        template = new THREE.Mesh(
          new THREE.BoxGeometry(0.24, 0.24, 0.24),
          new THREE.MeshStandardMaterial({ color: 0x27c5d3, roughness: 0.3 }),
        );
      }
      scene.add(poseFixture(template, descriptor, f));
      // Allow progress text and input to paint between large fixture models.
      await new Promise((resolve) => setTimeout(resolve, 0));
    }
    scene.updateMatrixWorld(true);
    const bounds = new THREE.Box3().setFromObject(scene);
    if (
      bounds.isEmpty() ||
      ![...bounds.min, ...bounds.max].every(Number.isFinite)
    )
      throw new Error("The scene has invalid or empty bounds.");
    return { scene, save };
  } catch (error) {
    disposeScene(scene);
    templates.forEach(disposeScene);
    throw error;
  }
}

export async function exportGLB(scene) {
  return new GLTFExporter().parseAsync(scene, {
    binary: true,
    onlyVisible: false,
  });
}
export async function loadGLB(bytes) {
  const manager = new THREE.LoadingManager();
  manager.setURLModifier((url) => {
    if (!url.startsWith("blob:") && !url.startsWith("data:"))
      throw new Error(
        "This GLB references external files. Use a self-contained export.",
      );
    return url;
  });
  return (await new GLTFLoader(manager).parseAsync(bytes, "")).scene;
}

export async function readExportedGLB(file) {
  if (!file.size || file.size > MAX_SAVE_BYTES)
    throw new Error("Choose an exported GLB smaller than 350 MB.");
  const bytes = await file.arrayBuffer(),
    header = new DataView(bytes);
  if (
    bytes.byteLength < 20 ||
    header.getUint32(0, true) !== 0x46546c67 ||
    header.getUint32(4, true) !== 2 ||
    header.getUint32(8, true) !== bytes.byteLength ||
    header.getUint32(16, true) !== 0x4e4f534a ||
    header.getUint32(12, true) > bytes.byteLength - 20
  )
    throw new Error("This is not a valid GLB 2.0 file.");
  const json = JSON.parse(
    new TextDecoder().decode(
      new Uint8Array(bytes, 20, header.getUint32(12, true)),
    ),
  );
  const metadata = json.nodes?.find(
    (n) =>
      n.extras?.format === "com.venuevolume.web-scene" &&
      n.extras.version === 1,
  );
  if (
    !metadata ||
    !Number.isInteger(metadata.extras.fixtureCount) ||
    metadata.extras.fixtureCount < 0 ||
    metadata.extras.fixtureCount > 64
  )
    throw new Error("Choose a GLB exported from Venue Volume 3D review.");
  if (
    [...(json.buffers || []), ...(json.images || [])].some((item) => item.uri)
  )
    throw new Error(
      "This GLB references separate resources. Use a self-contained export.",
    );
  const model = await loadGLB(bytes);
  const bounds = new THREE.Box3().setFromObject(model);
  if (
    bounds.isEmpty() ||
    ![...bounds.min, ...bounds.max].every(Number.isFinite)
  ) {
    disposeScene(model);
    throw new Error("The GLB has invalid or empty scene geometry.");
  }
  const fixtures = [];
  model.traverse((o) => {
    if (o.userData.kind === "fixture")
      fixtures.push({
        id: o.userData.fixtureID,
        name: o.userData.fixtureName || o.name,
        assetID: o.userData.assetID,
      });
  });
  if (fixtures.length !== metadata.extras.fixtureCount) {
    disposeScene(model);
    throw new Error("This GLB is missing fixtures from its saved Load Out.");
  }
  return {
    model,
    name: metadata.name,
    roomName: metadata.extras.roomName || metadata.extras.roomID,
    setupID: metadata.extras.setupID,
    spawn: metadata.extras.spawn || null,
    ceilingTriangles: metadata.extras.ceilingTriangles || 0,
    wallTrianglesBySide: metadata.extras.wallTrianglesBySide || {},
    roomID: metadata.extras.roomID,
    fixtures,
    glb: new Blob([bytes], { type: "model/gltf-binary" }),
  };
}

export function isometricCamera(bounds, direction, aspect = 4 / 3) {
  const center = bounds.getCenter(new THREE.Vector3()),
    radius = Math.max(0.1, bounds.getSize(new THREE.Vector3()).length() / 2);
  const camera = new THREE.OrthographicCamera(
    -radius * aspect,
    radius * aspect,
    radius,
    -radius,
    0.01,
    radius * 8,
  );
  camera.position
    .copy(center)
    .add(
      new THREE.Vector3(...direction).normalize().multiplyScalar(radius * 3),
    );
  camera.lookAt(center);
  camera.updateMatrixWorld(true);
  // Project all corners and fit tightly, including fixtures outside room bounds.
  let width = 0,
    height = 0;
  for (const x of [bounds.min.x, bounds.max.x])
    for (const y of [bounds.min.y, bounds.max.y])
      for (const z of [bounds.min.z, bounds.max.z]) {
        const v = new THREE.Vector3(x, y, z).applyMatrix4(
          camera.matrixWorldInverse,
        );
        width = Math.max(width, Math.abs(v.x));
        height = Math.max(height, Math.abs(v.y));
      }
  const half = Math.max(height, width / aspect, 0.1) * 1.12;
  camera.left = -half * aspect;
  camera.right = half * aspect;
  camera.top = half;
  camera.bottom = -half;
  camera.updateProjectionMatrix();
  return camera;
}
