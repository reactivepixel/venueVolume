import { test } from "node:test";
import assert from "node:assert/strict";
import { fixturePlacementLink } from "../src/vision-pro-link.js";

test("native placement URL contains only canonical Load Out and fixture identities", () => {
  assert.equal(
    fixturePlacementLink(
      "10000000-0000-4000-8000-00000000000A",
      "20000000-0000-4000-8000-000000000002",
    ),
    "venuevolume://place?version=1&loadout=10000000-0000-4000-8000-00000000000a&fixture=20000000-0000-4000-8000-000000000002",
  );
});
test("labels, path traversal and query injection are not native identities", () => {
  for (const bad of [
    "Load Out 1",
    "../room",
    "?fixture=evil",
    "10000000-0000-4000-8000-000000000001&download=evil",
    "",
  ]) {
    assert.throws(() =>
      fixturePlacementLink(bad, "20000000-0000-4000-8000-000000000002"),
    );
    assert.throws(() =>
      fixturePlacementLink("10000000-0000-4000-8000-000000000001", bad),
    );
  }
});
