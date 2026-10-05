// Every catalog entry must resolve its real USDZ and all native joint members.
import { chromium } from "@playwright/test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
const catalog = JSON.parse(
  await readFile(
    new URL("../../../assets/fixtures/runtime-catalog.json", import.meta.url),
  ),
);
const browser = await chromium.launch({
  executablePath: process.env.VV_CHROMIUM_EXECUTABLE || "/usr/bin/chromium",
  headless: true,
  args: ["--no-sandbox"],
});
try {
  const page = await browser.newPage();
  await page.route("**/api/venues**", (r) =>
    r.fulfill({ json: { venues: [] } }),
  );
  await page.goto(process.env.VV_BASE_URL || "http://127.0.0.1:5177");
  const result = await page.evaluate(async (catalog) => {
    const { sceneFromSave, disposeScene, ISOMETRIC_VIEWS, isometricCamera } =
      await import("/src/venue-scene.js");
    const { sha256 } = await import("/src/venue-save.js");
    const THREE = await import("/node_modules/three/build/three.module.js");
    const mesh = JSON.stringify({
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
    });
    const manifest = {
      schemaVersion: 1,
      id: "scan",
      version: "one",
      title: "Test scan",
      units: "meters",
      upAxis: "Y",
      forwardAxis: "-Z",
      assetTranslation: [0, 1, 0],
      asset: {
        file: "environment.mesh.json",
        bytes: mesh.length,
        sha256: await sha256(new TextEncoder().encode(mesh)),
      },
    };
    const failed = [];
    for (const a of catalog) {
      const channels = Array(16).fill(128);
      const f = {
        id: "10000000-0000-4000-8000-000000000001",
        name: a.name,
        assetID: a.id,
        position: { x: 2, y: 1, z: -2 },
        orientation: { x: 0, y: 0, z: 0, w: 1 },
        scale: { x: 1, y: 1, z: 1 },
        universe: 1,
        startAddress: 1,
        channels,
      };
      const s = {
        format: "com.venuevolume.save",
        schemaVersion: 1,
        room: { manifest, origin: "scanned" },
        setup: {
          schemaVersion: 1,
          id: "20000000-0000-4000-8000-000000000001",
          name: "Scan review",
          roomID: "scan-one",
          placements: {
            schemaVersion: 1,
            environmentID: "scan",
            environmentVersion: "one",
            fixtures: [f],
          },
        },
        asset: btoa(mesh),
      };
      try {
        const { scene } = await sceneFromSave(
          new File([JSON.stringify(s)], "scan.venuevolume"),
        );
        const room = scene.children[0];
        if (room.position.y !== 1) throw new Error("Scan origin lost");
        const rig = scene.children[1];
        const box = new THREE.Box3().setFromObject(rig);
        if (box.isEmpty()) throw new Error("No fixture geometry");
        // Neutral articulated assembly retains authored metre bounds, with small USD float tolerance.
        const expectedMin = a.boundsMin.map((v, i) => v + [2, 1, -2][i]),
          expectedMax = a.boundsMax.map((v, i) => v + [2, 1, -2][i]);
        if (
          box.min
            .toArray()
            .some((v, i) => Math.abs(v - expectedMin[i]) > 0.015) ||
          box.max.toArray().some((v, i) => Math.abs(v - expectedMax[i]) > 0.015)
        )
          throw new Error(
            `Wrong fixture bounds: ${box.min.toArray()} / ${box.max.toArray()}`,
          );
        // Nonneutral pose changes the exact joints by the same formula as FixtureRig.swift.
        for (const j of a.joints) {
          const object = rig.getObjectByName(`vv-joint:${j.id}`);
          if (!object) throw new Error(`Missing joint ${j.id}`);
        }
        const bounds = new THREE.Box3().setFromObject(scene);
        for (const v of ISOMETRIC_VIEWS) {
          const camera = isometricCamera(bounds, v.direction);
          const dir = camera.position
            .clone()
            .sub(bounds.getCenter(new THREE.Vector3()))
            .normalize();
          if (
            dir
              .toArray()
              .some(
                (d, i) => Math.abs(d - v.direction[i] / Math.sqrt(3)) > 1e-6,
              )
          )
            throw new Error("Non-isometric projection");
          for (const x of [bounds.min.x, bounds.max.x])
            for (const y of [bounds.min.y, bounds.max.y])
              for (const z of [bounds.min.z, bounds.max.z]) {
                const p = new THREE.Vector3(x, y, z).project(camera);
                if (Math.abs(p.x) > 1 || Math.abs(p.y) > 1 || Math.abs(p.z) > 1)
                  throw new Error("Clipped export view");
              }
        }
        disposeScene(scene);
      } catch (e) {
        failed.push({ id: a.id, error: e.message });
      }
    }
    return { checked: catalog.length, failed };
  }, catalog);
  console.log(JSON.stringify(result, null, 2));
  assert.deepEqual(result.failed, []);
} finally {
  await browser.close();
}
