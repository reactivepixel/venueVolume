import { chromium } from "@playwright/test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
const root = new URL("../../../", import.meta.url);
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
  for (const room of ["Classroom", "MappedRoom", "Fortress"]) {
    const directory = `apps/visionos/VenueVolume/Environments/${room}/`;
    const manifest = JSON.parse(
      await readFile(new URL(directory + "environment.json", root)),
    );
    const asset = (
      await readFile(new URL(directory + "environment.usdz", root))
    ).toString("base64");
    const save = {
      format: "com.venuevolume.save",
      schemaVersion: 1,
      room: { manifest, origin: "bundled" },
      setup: {
        schemaVersion: 1,
        id: "20000000-0000-4000-8000-000000000001",
        name: room,
        roomID: `${manifest.id}-${manifest.version}`,
        placements: {
          schemaVersion: 1,
          environmentID: manifest.id,
          environmentVersion: manifest.version,
          fixtures: [],
        },
      },
      asset,
    };
    const result = await page.evaluate(async (save) => {
      const { sceneFromSave, exportGLB, loadGLB, disposeScene } = await import(
        "/src/venue-scene.js"
      );
      const { scene } = await sceneFromSave(
        new File([JSON.stringify(save)], "venue.venuevolume"),
      );
      let triangles = 0,
        meshes = 0,
        ceilingTriangles = 0,
        textures = 0;
      scene.traverse((o) => {
        if (o.isMesh) {
          meshes++;
          const count =
            (o.geometry.index?.count || o.geometry.attributes.position.count) /
            3;
          triangles += count;
          if (o.userData.venuePart === "ceiling") ceilingTriangles += count;
          for (const m of Array.isArray(o.material) ? o.material : [o.material])
            if (m.map) textures++;
        }
      });
      const glb = await exportGLB(scene),
        restored = await loadGLB(glb);
      let restoredTriangles = 0,
        restoredCeiling = 0;
      restored.traverse((o) => {
        if (o.isMesh) {
          const count =
            (o.geometry.index?.count || o.geometry.attributes.position.count) /
            3;
          restoredTriangles += count;
          if (o.userData.venuePart === "ceiling") restoredCeiling += count;
        }
      });
      disposeScene(scene);
      disposeScene(restored);
      return {
        triangles,
        meshes,
        ceilingTriangles,
        restoredTriangles,
        restoredCeiling,
        textures,
        glbBytes: glb.byteLength,
      };
    }, save);
    console.log(room, result);
    assert.equal(result.triangles, manifest.geometry.triangles);
    assert.ok(result.meshes >= manifest.geometry.meshes);
    assert.ok(result.ceilingTriangles > 0);
    assert.equal(result.restoredTriangles, manifest.geometry.triangles);
    assert.equal(result.restoredCeiling, result.ceilingTriangles);
  }
} finally {
  await browser.close();
}
