const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Navigation, not a transport for browser storage, scan bytes or credentials.
export function fixturePlacementLink(loadOutId, fixtureId) {
  if (!uuid.test(loadOutId) || !uuid.test(fixtureId)) {
    throw new Error(
      "This Load Out and fixture need stable UUIDs before they can be opened in Vision Pro.",
    );
  }
  const query = new URLSearchParams({
    version: "1",
    loadout: loadOutId.toLowerCase(),
    fixture: fixtureId.toLowerCase(),
  });
  return `venuevolume://place?${query}`;
}
