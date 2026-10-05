import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

// Serve only catalogued fixture resources; bundle the same immutable models for
// static deployments. Browser requests are lazy, one model per fixture type.
const root = fileURLToPath(new URL("../..", import.meta.url));
const catalog = JSON.parse(
  fs.readFileSync(path.join(root, "assets/fixtures/runtime-catalog.json")),
);
export default function fixtureAssets() {
  const files = new Map(
    catalog.map((asset) => [
      `/fixture-models/${asset.id}.usdz`,
      path.join(root, "apps/visionos/VenueVolume", asset.resource),
    ]),
  );
  return {
    name: "venue-fixture-assets",
    configureServer(server) {
      server.middlewares.use((req, res, next) => {
        const file = files.get(req.url?.split("?")[0]);
        if (!file) return next();
        res.setHeader("Content-Type", "model/vnd.usdz+zip");
        fs.createReadStream(file).on("error", next).pipe(res);
      });
    },
    generateBundle() {
      for (const [url, file] of files) {
        this.emitFile({
          type: "asset",
          fileName: url.slice(1),
          source: fs.readFileSync(file),
        });
      }
    },
  };
}
