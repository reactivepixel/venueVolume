import { fixtureRows } from "../src/catalog.js";
export async function installWorkspaceFixture(context) {
  const venues = ["The Glasshouse", "Mercury Hall"].map((name, i) => ({
    id: `scan-${i}`,
    name,
    status: "ready",
    setupStatus: "configured",
    assetUrl: `/scan-${i}.ply`,
  }));
  const units = fixtureRows.map((u) => ({ ...u, ownership: "Owned" }));
  const state = {
    version: 2,
    units,
    tours: [],
    activity: [],
    loadouts: venues.map((v, i) => ({
      id: `review-${i}`,
      name: `${v.name} Load Out`,
      venueId: v.id,
      scan: v,
      tourId: "",
      stopId: "",
      baseUnitIds: [],
      extraUnitIds: units.map((u) => u.id),
      placements: Object.fromEntries(
        units.map((u) => [u.id, { x: 0, y: 0, z: 0, yaw: 0 }]),
      ),
      patch: Object.fromEntries(
        units.map((u) => [u.id, { universe: u.universe, address: u.address }]),
      ),
      scanReviewed: true,
    })),
  };
  await context.addInitScript((state) => {
    if (
      location.protocol.startsWith("http") &&
      !localStorage.getItem("vv-workspace-v2")
    )
      localStorage.setItem("vv-workspace-v2", JSON.stringify(state));
  }, state);
  await context.route("**/api/venues", (route) =>
    route.fulfill({ json: { venues, maxUploadBytes: 10737418240 } }),
  );
}
