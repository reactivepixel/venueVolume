import { chromium, expect } from "@playwright/test";
import assert from "node:assert/strict";
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { createHash } from "node:crypto";
import { unzipSync } from "fflate";
const base = process.env.VV_BASE_URL || "http://127.0.0.1:5177";
const root = new URL("../../../", import.meta.url),
  output = new URL("tmp/venue-web-export/", root);
await mkdir(output, { recursive: true });
const read = async (path) =>
  JSON.parse(await readFile(new URL(path, root), "utf8"));
const catalog = await read("assets/fixtures/runtime-catalog.json");
const manifest = await read(
  "apps/visionos/VenueVolume/Environments/Classroom/environment.json",
);
const assets = [
  catalog[0],
  catalog[1],
  catalog.find((a) => a.id.includes("rogue")),
].filter(Boolean);
const fixtures = assets.map((asset, i) => ({
  id: `10000000-0000-4000-8000-00000000000${i + 1}`,
  name: asset.name,
  assetID: asset.id,
  universe: 1,
  startAddress: 1 + i * 16,
  channels: [255, 100, 200, 255, 180, 160, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  position: { x: 2 + i * 1.4, y: 0.74, z: -3.68 },
  orientation: { x: 0, y: Math.sin(0.2), z: 0, w: Math.cos(0.2) },
  scale: { x: 1, y: 1, z: 1 },
}));
const save = {
  format: "com.venuevolume.save",
  schemaVersion: 1,
  room: { manifest, origin: "bundled" },
  setup: {
    schemaVersion: 1,
    id: "20000000-0000-4000-8000-000000000001",
    name: "Classroom fixture review",
    modified: 812340000,
    roomID: `${manifest.id}-${manifest.version}`,
    placements: {
      schemaVersion: 1,
      environmentID: manifest.id,
      environmentVersion: manifest.version,
      revision: 1,
      fixtures,
    },
    presets: [],
    whiteRoom: false,
    houseLight: 1,
  },
  asset: (
    await readFile(
      new URL(
        "apps/visionos/VenueVolume/Environments/Classroom/environment.usdz",
        root,
      ),
    )
  ).toString("base64"),
};
await writeFile(new URL("classroom.venuevolume", output), JSON.stringify(save));
const browser = await chromium.launch({
  executablePath: process.env.VV_CHROMIUM_EXECUTABLE || "/usr/bin/chromium",
  headless: true,
  args: [
    "--no-sandbox",
    "--use-gl=angle",
    "--use-angle=swiftshader",
    "--enable-unsafe-swiftshader",
  ],
});
const page = await browser.newPage({ viewport: { width: 1536, height: 1250 } }),
  errors = [];
page.on("pageerror", (e) => errors.push(e.message));
await page.route("**/api/venues**", (r) => r.fulfill({ json: { venues: [] } }));
try {
  await page.goto(`${base}/?screen=scene-review`);
  await expect(
    page.getByRole("heading", { name: "Your venue, ready to review" }),
  ).toBeVisible();
  await page
    .getByLabel("Import visionOS save", { exact: true })
    .setInputFiles(new URL("classroom.venuevolume", output).pathname);
  await expect(
    page.getByRole("button", { name: "Export all 8 views" }),
  ).toBeEnabled({ timeout: 90000 });
  await expect(page.getByRole("alert")).toHaveCount(0);
  const startPosition = await page.getByLabel("Viewer position").innerText();
  assert.match(startPosition, /X 2\.66.*Y 1\.65.*Z -1\.10/);
  await page
    .locator(".venue-scene-canvas canvas")
    .click({ position: { x: 120, y: 120 } });
  await page.waitForFunction(
    () => document.pointerLockElement?.tagName === "CANVAS",
  );
  await page.waitForTimeout(100);
  await page.keyboard.down("w");
  await page.waitForTimeout(550);
  await page.keyboard.up("w");
  await expect(page.getByLabel("Viewer position")).not.toHaveText(
    startPosition,
  );
  await page.keyboard.press("Escape");
  await page.getByRole("button", { name: "Walk from spawn" }).click();
  await expect(page.getByLabel("Viewer position")).toHaveText(startPosition);
  await page
    .getByRole("button", { name: "upper front right", exact: true })
    .click();
  await expect(page.getByLabel("Viewer position")).toHaveCount(0);
  const hiddenEvent = page.waitForEvent("download");
  await page
    .getByRole("button", { name: "Export selected view (.png)" })
    .click();
  const hiddenImage = await hiddenEvent;
  await hiddenImage.saveAs(new URL("ceiling-hidden.png", output).pathname);
  await page.getByLabel("Hide ceiling").uncheck();
  const visibleEvent = page.waitForEvent("download");
  await page
    .getByRole("button", { name: "Export selected view (.png)" })
    .click();
  const visibleImage = await visibleEvent;
  await visibleImage.saveAs(new URL("ceiling-visible.png", output).pathname);
  assert.notEqual(
    createHash("sha256")
      .update(await readFile(new URL("ceiling-hidden.png", output)))
      .digest("hex"),
    createHash("sha256")
      .update(await readFile(new URL("ceiling-visible.png", output)))
      .digest("hex"),
    "Ceiling toggle must change rendered geometry",
  );
  await page.getByLabel("Hide ceiling").check();
  await page.screenshot({
    path: new URL("02-open-isometric.png", output).pathname,
    fullPage: true,
  });
  await page.screenshot({
    path: new URL("01-3d-review.png", output).pathname,
    fullPage: true,
  });
  const glbEvent = page.waitForEvent("download");
  await page
    .getByRole("button", { name: "Download 3D (.glb)", exact: true })
    .click();
  const glbDownload = await glbEvent;
  await glbDownload.saveAs(new URL("classroom.glb", output).pathname);
  const bytes = await readFile(new URL("classroom.glb", output));
  assert.equal(bytes.readUInt32LE(0), 0x46546c67);
  assert.equal(bytes.readUInt32LE(8), bytes.length);
  const gltf = JSON.parse(
    bytes.subarray(20, 20 + bytes.readUInt32LE(12)).toString(),
  );
  const source = gltf.nodes.find(
    (n) => n.extras?.format === "com.venuevolume.web-scene",
  );
  assert.deepEqual(source.extras.spawn.position, manifest.spawn.position);
  assert.equal(source.extras.spawn.yaw, manifest.spawn.yaw);
  assert.ok(source.extras.ceilingTriangles > 0);
  assert.equal(
    gltf.nodes.filter((n) => n.extras?.kind === "fixture").length,
    fixtures.length,
  );
  for (const fixture of fixtures) {
    const node = gltf.nodes.find((n) => n.extras?.fixtureID === fixture.id);
    assert.ok(node, fixture.name);
    assert.deepEqual(
      node.matrix.slice(12, 15),
      Object.values(fixture.position),
    );
  }
  assert.ok(
    gltf.nodes.some((n) => n.extras?.venuePart === "ceiling"),
    "The GLB retains hidden roof geometry",
  );
  assert.ok(
    gltf.nodes.some((n) => n.name === "vv-joint:tilt"),
    "Articulated fixture hierarchy retained",
  );
  // Independently reload GLB and check restored geometry, world transforms and finite bounds.
  const roundTrip = await page.evaluate(
    async ({ assets, fixtures }) => {
      const { sceneStorage } = await import("/src/scene-storage.js");
      const { loadGLB } = await import("/src/venue-scene.js");
      const THREE = await import("/node_modules/three/build/three.module.js");
      const [record] = await sceneStorage("list");
      const scene = await loadGLB(await record.glb.arrayBuffer());
      let meshes = 0;
      scene.traverse((o) => {
        if (o.isMesh) meshes++;
      });
      const box = new THREE.Box3().setFromObject(scene);
      for (let i = 0; i < assets.length; i++) {
        let rig;
        scene.traverse((o) => {
          if (o.userData.fixtureID === fixtures[i].id) rig = o;
        });
        for (const j of assets[i].joints) {
          let joint;
          rig.traverse((o) => {
            if (o.userData.jointID === j.id) joint = o;
          });
          const angle = j.continuous
            ? 0
            : (((fixtures[i].channels[j.channel] - 128) / 255) *
                j.travel *
                Math.PI) /
              180;
          const expected = new THREE.Quaternion().setFromAxisAngle(
            new THREE.Vector3(...j.axis).normalize(),
            angle,
          );
          if (joint.quaternion.angleTo(expected) > 1e-5)
            throw new Error(`Wrong saved pose for ${assets[i].id} ${j.id}`);
        }
      }
      return { meshes, extent: box.getSize(new THREE.Vector3()).toArray() };
    },
    { assets, fixtures },
  );
  assert.ok(roundTrip.meshes > 400);
  assert.ok(roundTrip.extent.every((n) => n > 0 && n < 100));
  const zipEvent = page.waitForEvent("download", { timeout: 90000 });
  await page
    .getByRole("button", { name: "Export all 8 views", exact: true })
    .click();
  const zipDownload = await zipEvent;
  await zipDownload.saveAs(
    new URL("classroom-isometric-views.zip", output).pathname,
  );
  const zipped = unzipSync(
    await readFile(new URL("classroom-isometric-views.zip", output)),
  );
  const pngs = Object.entries(zipped).filter(([name]) => name.endsWith(".png"));
  assert.equal(pngs.length, 8);
  assert.equal(
    new Set(pngs.map(([, b]) => createHash("sha256").update(b).digest("hex")))
      .size,
    8,
  );
  for (const [name, png] of pngs) {
    const b = Buffer.from(png);
    assert.equal(b.readUInt32BE(16), 1600);
    assert.equal(b.readUInt32BE(20), 1200);
    await writeFile(new URL(name, output), png);
  }
  // Compare rendered pixels above the caption, so different labels alone
  // cannot make eight identical camera images pass this test.
  const visualHashes = await page.evaluate(
    async (images) => {
      const hashes = [];
      for (const base64 of images) {
        const img = new Image();
        img.src = `data:image/png;base64,${base64}`;
        await img.decode();
        const canvas = document.createElement("canvas");
        canvas.width = 1600;
        canvas.height = 1152;
        const ctx = canvas.getContext("2d");
        ctx.drawImage(img, 0, 0);
        const bytes = ctx.getImageData(0, 0, 1600, 1152).data;
        const digest = await crypto.subtle.digest("SHA-256", bytes);
        hashes.push(Array.from(new Uint8Array(digest)).join(","));
      }
      return hashes;
    },
    pngs.map(([, png]) => Buffer.from(png).toString("base64")),
  );
  assert.equal(
    new Set(visualHashes).size,
    8,
    "Eight different rendered camera views",
  );
  const views = JSON.parse(new TextDecoder().decode(zipped["views.json"]));
  assert.equal(views.views.length, 8);
  assert.equal(views.transparentVenue, true);
  assert.equal(views.ceilingHidden, true);
  await page
    .getByRole("button", { name: fixtures[1].name, exact: true })
    .click();
  await page.screenshot({
    path: new URL("02-fixture-detail.png", output).pathname,
    fullPage: true,
  });
  await page.reload();
  await expect(page.getByRole("button", { name: "Open snapshot" })).toHaveCount(
    1,
  );
  await page.getByRole("button", { name: "Open snapshot" }).click();
  await expect(
    page.getByRole("button", { name: "Export all 8 views" }),
  ).toBeEnabled({ timeout: 30000 });
  await page
    .getByLabel("Open exported GLB", { exact: true })
    .setInputFiles(new URL("classroom.glb", output).pathname);
  await expect(page.getByRole("button", { name: "Open snapshot" })).toHaveCount(
    2,
    { timeout: 30000 },
  );
  await expect(
    page.getByRole("button", { name: "Export all 8 views" }),
  ).toBeEnabled();
  await expect(page.getByRole("alert")).toHaveCount(0);
  await expect(page.getByLabel("Viewer position")).toHaveText(startPosition);
  await page.getByLabel("See fixtures through venue").uncheck();
  await page.screenshot({
    path: new URL("03-full-venue.png", output).pathname,
    fullPage: true,
  });
  await page.getByLabel("Open exported GLB", { exact: true }).setInputFiles({
    name: "broken.glb",
    mimeType: "model/gltf-binary",
    buffer: Buffer.from("not a glb"),
  });
  await expect(page.getByRole("alert")).toContainText("valid GLB");
  await expect(page.getByRole("button", { name: "Open snapshot" })).toHaveCount(
    2,
  );
  // Failed imports leave the previously open scene and stored records intact.
  const bad = structuredClone(save);
  bad.room.manifest.asset.sha256 = "0".repeat(64);
  await page.getByLabel("Import visionOS save", { exact: true }).setInputFiles({
    name: "broken.venuevolume",
    mimeType: "application/json",
    buffer: Buffer.from(JSON.stringify(bad)),
  });
  await expect(page.getByRole("alert")).toContainText("checksum");
  await expect(page.getByRole("button", { name: "Open snapshot" })).toHaveCount(
    2,
  );
  await expect(
    page.getByRole("heading", {
      name: "Classroom fixture review",
      exact: true,
    }),
  ).toBeVisible();
  // Unsupported catalog models must fail visibly, never silently omit fixtures.
  bad.room.manifest.asset.sha256 = manifest.asset.sha256;
  bad.setup.placements.fixtures[0].assetID = "missing-fixture";
  await page.getByLabel("Import visionOS save", { exact: true }).setInputFiles({
    name: "missing.venuevolume",
    mimeType: "application/json",
    buffer: Buffer.from(JSON.stringify(bad)),
  });
  await expect(page.getByRole("alert")).toContainText("unavailable", {
    timeout: 30000,
  });
  await page.getByRole("button", { name: "Open snapshot" }).first().click();
  await expect(
    page.getByRole("button", { name: "Export all 8 views" }),
  ).toBeEnabled();
  await page.getByLabel("See fixtures through venue").check();
  await page.setViewportSize({ width: 390, height: 844 });
  await page.screenshot({
    path: new URL("04-mobile.png", output).pathname,
    fullPage: true,
  });
  assert.equal(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
    true,
  );
  assert.deepEqual(errors, []);
  console.log(
    `PASS: ${roundTrip.meshes} real meshes, GLB transforms and reload, 8 distinct PNGs, persistence, failures and mobile layout.`,
  );
} finally {
  await browser.close();
}
