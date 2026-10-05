// Portable visionOS save validation, independent of rendering and persistence.
export const MAX_SAVE_BYTES = 350_000_000;
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const fail = (message) => {
  throw new Error(message);
};
const finite = (n) => typeof n === "number" && Number.isFinite(n);
const vector = (v, keys) =>
  v && keys.every((k) => finite(v[k]) && Math.abs(v[k]) < 1000);
export async function sha256(bytes) {
  return Array.from(
    new Uint8Array(await crypto.subtle.digest("SHA-256", bytes)),
    (b) => b.toString(16).padStart(2, "0"),
  ).join("");
}
export async function readVenueSave(file) {
  if (!file.size || file.size > MAX_SAVE_BYTES)
    fail("Choose a .venuevolume save smaller than 350 MB.");
  let save;
  try {
    save = JSON.parse(await file.text());
  } catch {
    fail("This file is not a valid Venue Volume save.");
  }
  if (save?.format !== "com.venuevolume.save" || save.schemaVersion !== 1)
    fail("Unsupported Venue Volume save version.");
  const m = save.room?.manifest,
    s = save.setup,
    p = s?.placements;
  if (
    m?.schemaVersion !== 1 ||
    m.units !== "meters" ||
    m.upAxis !== "Y" ||
    m.forwardAxis !== "-Z"
  )
    fail("The venue must use metres, Y-up and −Z forward.");
  if (
    s?.schemaVersion !== 1 ||
    !uuid.test(s.id) ||
    typeof s.name !== "string" ||
    !s.name.trim() ||
    s.name.length > 120 ||
    s.roomID !== `${m.id}-${m.version}` ||
    p?.schemaVersion !== 1 ||
    p.environmentID !== m.id ||
    p.environmentVersion !== m.version
  )
    fail("The Load Out does not match this venue version.");
  if (
    m.assetTranslation &&
    (!Array.isArray(m.assetTranslation) ||
      m.assetTranslation.length !== 3 ||
      !m.assetTranslation.every((n) => finite(n) && Math.abs(n) < 1000))
  )
    fail("Invalid venue origin.");
  if (!Array.isArray(p.fixtures) || p.fixtures.length > 64)
    fail("A save may contain at most 64 fixtures.");
  const ids = new Set();
  for (const f of p.fixtures) {
    if (
      !uuid.test(f.id) ||
      ids.has(f.id.toLowerCase()) ||
      typeof f.name !== "string" ||
      !vector(f.position, ["x", "y", "z"]) ||
      !vector(f.scale, ["x", "y", "z"]) ||
      !["x", "y", "z"].every((k) => f.scale[k] > 0) ||
      !vector(f.orientation, ["x", "y", "z", "w"]) ||
      Math.abs(
        Math.hypot(...["x", "y", "z", "w"].map((k) => f.orientation[k])) - 1,
      ) > 0.01 ||
      !Array.isArray(f.channels) ||
      !f.channels.length ||
      f.channels.length > 16 ||
      !f.channels.every((n) => Number.isInteger(n) && n >= 0 && n <= 255) ||
      !Number.isInteger(f.universe) ||
      f.universe < 1 ||
      f.universe > 63999 ||
      !Number.isInteger(f.startAddress) ||
      f.startAddress < 1 ||
      f.startAddress + f.channels.length > 513
    )
      fail("A fixture has invalid identity, placement or channel values.");
    if (
      f.aimOverride &&
      !["pan", "tilt"].every(
        (k) =>
          Number.isInteger(f.aimOverride[k]) &&
          f.aimOverride[k] >= 0 &&
          f.aimOverride[k] <= 255,
      )
    )
      fail("Invalid fixture aim.");
    if (
      f.jointOverrides &&
      !Object.values(f.jointOverrides).every(
        (n) => Number.isInteger(n) && n >= 0 && n <= 255,
      )
    )
      fail("Invalid fixture joint values.");
    ids.add(f.id.toLowerCase());
  }
  if (!["environment.usdz", "environment.mesh.json"].includes(m.asset?.file))
    fail("This save does not contain a supported room mesh.");
  if (
    typeof save.asset !== "string" ||
    !/^[A-Za-z0-9+/]*={0,2}$/.test(save.asset)
  )
    fail("The embedded venue asset is invalid.");
  let asset;
  try {
    asset = Uint8Array.from(atob(save.asset), (c) => c.charCodeAt(0));
  } catch {
    fail("The embedded venue asset is invalid.");
  }
  if (
    !asset.length ||
    asset.length !== m.asset.bytes ||
    (await sha256(asset)) !== m.asset.sha256
  )
    fail(
      "The venue asset is incomplete or its checksum does not match. Export the save again.",
    );
  return { save, asset };
}

export function readScannedMesh(bytes) {
  let mesh;
  try {
    mesh = JSON.parse(new TextDecoder().decode(bytes));
  } catch {
    fail("The scanned room mesh is invalid.");
  }
  if (
    mesh?.schemaVersion !== 1 ||
    !Array.isArray(mesh.chunks) ||
    !mesh.chunks.length ||
    mesh.chunks.length > 2048
  )
    fail("Unsupported or empty scanned room mesh.");
  let triangles = 0;
  for (const c of mesh.chunks) {
    if (
      !Array.isArray(c.vertices) ||
      !c.vertices.length ||
      c.vertices.length > 1_000_000 ||
      !c.vertices.every((v) => vector(v, ["x", "y", "z"])) ||
      !Array.isArray(c.triangles) ||
      !c.triangles.length ||
      c.triangles.length % 3 ||
      !c.triangles.every(
        (i) => Number.isInteger(i) && i >= 0 && i < c.vertices.length,
      )
    )
      fail("The scanned room has invalid triangles.");
    triangles += c.triangles.length / 3;
  }
  if (triangles > 1_000_000)
    fail("The scanned room exceeds one million triangles.");
  return mesh;
}
