import { patchErrors } from "./model.js";

export const workspaceKey = "vv-workspace-v2";
export const emptyWorkspace = () => ({
  version: 2,
  units: [],
  tours: [],
  loadouts: [],
  activity: [],
});
const unique = (items) => [...new Set(items)];
const requireValue = (condition, message) => {
  if (!condition) throw new Error(message);
};
const named = (name) => {
  requireValue(typeof name === "string" && name.trim(), "Enter a name.");
  return name.trim();
};
export const inventoryIds = (loadout) =>
  unique([...loadout.baseUnitIds, ...loadout.extraUnitIds]);
export function fixturesFor(state, loadout) {
  return inventoryIds(loadout)
    .map((id) => state.units.find((unit) => unit.id === id))
    .filter(Boolean)
    .map((unit) => ({
      ...unit,
      ...(loadout.patch[unit.id] || { universe: 1, address: 0 }),
    }));
}
export function baseChanges(state, loadout) {
  const tour = state.tours.find((t) => t.id === loadout.tourId);
  const next = tour?.baseUnitIds || [];
  return {
    added: next.filter((id) => !loadout.baseUnitIds.includes(id)),
    removed: loadout.baseUnitIds.filter((id) => !next.includes(id)),
  };
}
export function readiness(state, loadout) {
  const ids = inventoryIds(loadout);
  const change = baseChanges(state, loadout);
  const issues = [];
  if (!ids.length) issues.push("Select fixture inventory.");
  const unplaced = ids.filter((id) => !loadout.placements[id]);
  if (unplaced.length)
    issues.push(
      `Place ${unplaced.length} fixture${unplaced.length === 1 ? "" : "s"}.`,
    );
  if (!loadout.scanReviewed) issues.push("Review the scan origin and scale.");
  if (change.added.length || change.removed.length)
    issues.push("Review changes to Tour base inventory.");
  issues.push(...patchErrors(fixturesFor(state, loadout)));
  return issues;
}
export function transition(state, action, venues = []) {
  const next = structuredClone(state);
  const find = (list, id) => {
    const item = list.find((row) => row.id === id);
    requireValue(item, "This item no longer exists.");
    return item;
  };
  const checkUnits = (ids) => {
    requireValue(Array.isArray(ids), "Select inventory.");
    ids.forEach((id) => find(next.units, id));
    return unique(ids);
  };
  const scan = (id) => {
    const venue = find(venues, id);
    requireValue(
      venue.status === "ready" &&
        venue.setupStatus === "configured" &&
        venue.assetUrl,
      "Choose an imported, processed venue scan.",
    );
    return { id: venue.id, name: venue.name, assetUrl: venue.assetUrl };
  };
  const createLoadout = (id, name, venueId, tourId = "", stopId = "") => {
    requireValue(
      !next.loadouts.some((l) => l.id === id),
      "This Load Out already exists.",
    );
    const tour = tourId ? find(next.tours, tourId) : null;
    const room = scan(venueId);
    const result = {
      id,
      name: named(name),
      venueId,
      scan: room,
      tourId,
      stopId,
      baseUnitIds: [...(tour?.baseUnitIds || [])],
      extraUnitIds: [],
      placements: {},
      patch: {},
      scanReviewed: false,
    };
    next.loadouts.push(result);
    return result;
  };
  let description = "";
  switch (action.type) {
    case "add-unit": {
      requireValue(
        !next.units.some((u) => u.id === action.id),
        "This fixture already exists.",
      );
      requireValue(
        Number.isInteger(action.footprint) &&
          action.footprint > 0 &&
          action.footprint <= 512,
        "DMX footprint must be 1–512 channels.",
      );
      next.units.push({
        id: action.id,
        name: named(action.name),
        model: named(action.model),
        footprint: action.footprint,
        mode: `${action.footprint} channel`,
        role: action.role?.trim() || "Unassigned",
        ownership: action.ownership || "Owned",
      });
      description = `Added fixture ${action.name}`;
      break;
    }
    case "remove-unit": {
      requireValue(
        !next.loadouts.some((l) => inventoryIds(l).includes(action.id)) &&
          !next.tours.some((t) => t.baseUnitIds.includes(action.id)),
        "This fixture is used by a Tour or Load Out. Remove those references first.",
      );
      const unit = find(next.units, action.id);
      next.units = next.units.filter((u) => u.id !== action.id);
      description = `Removed fixture ${unit.name}`;
      break;
    }
    case "add-tour":
      requireValue(
        !next.tours.some((t) => t.id === action.id),
        "This Tour already exists.",
      );
      next.tours.push({
        id: action.id,
        name: named(action.name),
        baseUnitIds: [],
        stops: [],
      });
      description = `Created Tour ${action.name}`;
      break;
    case "tour-base": {
      const tour = find(next.tours, action.id);
      tour.baseUnitIds = checkUnits(action.unitIds);
      description = `Updated base inventory for ${tour.name}; existing Load Outs await review`;
      break;
    }
    case "add-stop": {
      const tour = find(next.tours, action.tourId);
      requireValue(
        !tour.stops.some((s) => s.id === action.id),
        "This stop already exists.",
      );
      const loadout = createLoadout(
        action.loadoutId,
        action.name,
        action.venueId,
        tour.id,
        action.id,
      );
      tour.stops.push({
        id: action.id,
        venueId: loadout.venueId,
        loadoutId: loadout.id,
      });
      description = `Added stop with ${loadout.name} to ${tour.name}`;
      break;
    }
    case "add-loadout": {
      const l = createLoadout(action.id, action.name, action.venueId);
      description = `Created Load Out ${l.name}`;
      break;
    }
    case "copy-loadout": {
      const original = find(next.loadouts, action.id);
      const copy = createLoadout(action.newId, action.name, original.venueId);
      copy.extraUnitIds = inventoryIds(original);
      copy.placements = structuredClone(original.placements);
      copy.patch = structuredClone(original.patch);
      copy.scanReviewed = original.scanReviewed;
      description = `Duplicated ${original.name} as an independent Load Out`;
      break;
    }
    case "loadout-inventory": {
      const l = find(next.loadouts, action.id);
      const ids = checkUnits(action.unitIds);
      requireValue(
        l.baseUnitIds.every((id) => ids.includes(id)),
        "Tour base fixtures are required. Change the Tour base and review it here.",
      );
      const removed = inventoryIds(l).filter((id) => !ids.includes(id));
      requireValue(
        !removed.some((id) => l.placements[id]),
        "Return placed fixtures to inventory before removing them from this Load Out.",
      );
      l.extraUnitIds = ids.filter((id) => !l.baseUnitIds.includes(id));
      removed.forEach((id) => delete l.patch[id]);
      description = `Updated inventory for ${l.name}`;
      break;
    }
    case "adopt-base": {
      const l = find(next.loadouts, action.id);
      const tour = find(next.tours, l.tourId);
      const removed = l.baseUnitIds.filter(
        (id) => !tour.baseUnitIds.includes(id),
      );
      // Explicit review retains removed physical units as venue additions, including their placement/patch.
      l.extraUnitIds = unique([...l.extraUnitIds, ...removed]).filter(
        (id) => !tour.baseUnitIds.includes(id),
      );
      l.baseUnitIds = [...tour.baseUnitIds];
      description = `Reviewed Tour base for ${l.name}; removed base fixtures retained as local additions`;
      break;
    }
    case "place": {
      const l = find(next.loadouts, action.id);
      requireValue(
        inventoryIds(l).includes(action.unitId),
        "Select a fixture from this Load Out.",
      );
      requireValue(
        ["x", "y", "z", "yaw"].every((k) =>
          Number.isFinite(action.position[k]),
        ),
        "Enter finite placement coordinates.",
      );
      l.placements[action.unitId] = { ...action.position };
      description = `Saved fixture placement in ${l.name}`;
      break;
    }
    case "unplace": {
      const l = find(next.loadouts, action.id);
      delete l.placements[action.unitId];
      description = `Returned fixture to unplaced inventory in ${l.name}`;
      break;
    }
    case "patch": {
      const l = find(next.loadouts, action.id);
      requireValue(
        inventoryIds(l).includes(action.unitId),
        "This fixture is not in this Load Out.",
      );
      const unit = find(next.units, action.unitId);
      requireValue(
        Number.isInteger(action.universe) &&
          action.universe >= 1 &&
          Number.isInteger(action.address) &&
          action.address >= 1 &&
          action.address + unit.footprint - 1 <= 512,
        "Choose a universe and an address whose footprint fits slots 1–512.",
      );
      l.patch[action.unitId] = {
        universe: action.universe,
        address: action.address,
      };
      description = `Updated patch in ${l.name}`;
      break;
    }
    case "review-scan": {
      const l = find(next.loadouts, action.id);
      l.scanReviewed = action.reviewed;
      description = `Updated scan review for ${l.name}`;
      break;
    }
    default:
      throw new Error("Unknown workspace action.");
  }
  next.activity = [
    {
      id: action.eventId || crypto.randomUUID(),
      at: new Date().toISOString(),
      description,
    },
    ...next.activity,
  ].slice(0, 100);
  return next;
}
