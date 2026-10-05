import { chromium, expect } from "@playwright/test";
import assert from "node:assert/strict";
import { mkdir } from "node:fs/promises";
const base = process.env.VV_BASE_URL || "http://127.0.0.1:5175";
const output = new URL("../../../tmp/saas-ux-review/", import.meta.url)
  .pathname;
await mkdir(output, { recursive: true });
const browser = await chromium.launch({
  executablePath: process.env.VV_CHROMIUM_EXECUTABLE || "/usr/bin/chromium",
  headless: true,
  args: ["--no-sandbox"],
});
const page = await browser.newPage({ viewport: { width: 1440, height: 1050 } });
const errors = [];
page.on("pageerror", (e) => errors.push(e.message));
let checks = 0;
const record = {
  id: "10000000-0000-4000-8000-000000000001",
  name: "The Glasshouse",
  city: "Brooklyn, NY",
  filename: "glasshouse-walkthrough.mov",
  size: 243000000,
  status: "ready",
  setupStatus: "needs_setup",
  createdAt: "2026-10-04T09:00:00Z",
  assetUrl: "/api/venues/10000000-0000-4000-8000-000000000001/splat",
  show: "",
  template: "",
  frames: 620,
  registered: 588,
};
await page.route("**/api/venues**", async (route) => {
  const url = new URL(route.request().url());
  if (url.pathname.endsWith("/setup"))
    Object.assign(record, route.request().postDataJSON(), {
      setupStatus: "configured",
    });
  await route.fulfill({
    json:
      url.pathname === "/api/venues"
        ? { venues: [record], maxUploadBytes: 10737418240 }
        : record,
  });
});
const nav = async (label) =>
  page
    .getByRole("navigation", { name: "Workspace navigation" })
    .getByRole("button", { name: label, exact: true })
    .click();
const click = async (name) =>
  page.getByRole("button", { name, exact: true }).first().click();
const snap = async (name) => {
  await page.evaluate(() => document.fonts.ready);
  await page.screenshot({ path: `${output}${name}.png`, fullPage: true });
};
const state = () =>
  page.evaluate(() => JSON.parse(localStorage.getItem("vv-workspace-v2")));
try {
  await page.goto(base);
  await expect(
    page.getByRole("heading", { name: "A room. A rig. A plan." }),
  ).toBeVisible();
  checks++;
  await click("Create Load Out");
  await expect(page.getByText("An imported scan is required")).toBeVisible();
  await click("Open scanned venues");
  checks++;
  await page
    .getByRole("button", { name: /The Glasshouse.*glasshouse-walkthrough/ })
    .click();
  await expect(page.getByLabel("Show", { exact: true })).toHaveCount(0);
  await click("Import scanned venue");
  await expect(page.getByText("Imported scan", { exact: true })).toBeVisible();
  checks++;
  await nav("Fixture inventory");
  for (const name of ["Wash 01", "Wash 02", "Local spot"]) {
    await click("Add physical fixture");
    await page.getByLabel("Physical fixture name").fill(name);
    await page
      .getByLabel("Fixture profile / model")
      .fill(name === "Local spot" ? "VV Profile Spot" : "VV RGBW Wash");
    await click("Add fixture");
    await expect(page.getByRole("dialog")).toHaveCount(0);
  }
  await nav("Tours");
  await click("Create Tour");
  await page
    .getByLabel("Tour name", { exact: true })
    .fill("Afterglow · Fall Tour");
  await page
    .getByRole("dialog")
    .getByRole("button", { name: "Create Tour", exact: true })
    .click();
  await click("Edit base inventory");
  await page
    .getByRole("dialog")
    .getByRole("checkbox", { name: /Wash 01/ })
    .check();
  await page
    .getByRole("dialog")
    .getByRole("checkbox", { name: /Wash 02/ })
    .check();
  await click("Save inventory selection");
  await expect(page.getByRole("dialog")).toHaveCount(0);
  for (const name of ["Glasshouse · evening", "Glasshouse · matinee"]) {
    await click("Add venue stop");
    await page.getByLabel("Load Out name").fill(name);
    await click("Add stop & Load Out");
    await expect(page.getByRole("dialog")).toHaveCount(0);
  }
  assert.equal((await state()).tours[0].stops.length, 2);
  assert.notEqual(
    (await state()).tours[0].stops[0].loadoutId,
    (await state()).tours[0].stops[1].loadoutId,
  );
  checks++;
  await snap("03-tour");
  await page
    .getByRole("button", { name: /The Glasshouse Glasshouse · evening/ })
    .click();
  await click("Select fixtures");
  await page
    .getByRole("dialog")
    .getByRole("checkbox", { name: /Local spot/ })
    .check();
  await click("Save inventory selection");
  await expect(page.getByRole("dialog")).toHaveCount(0);
  assert.equal((await state()).loadouts[0].extraUnitIds.length, 1);
  assert.equal((await state()).tours[0].baseUnitIds.length, 2);
  assert.equal((await state()).loadouts[1].extraUnitIds.length, 0);
  checks++;
  const beforeHandoff = await state();
  await page
    .getByRole("button", { name: "Place in Vision Pro", exact: true })
    .first()
    .click();
  const nativeLink = page.getByRole("link", {
    name: "Open on this Vision Pro",
  });
  const expected = `venuevolume://place?version=1&loadout=${beforeHandoff.loadouts[0].id}&fixture=${beforeHandoff.loadouts[0].baseUnitIds[0]}`;
  await expect(nativeLink).toHaveAttribute("href", expected);
  await expect(page.getByLabel("Vision Pro placement link")).toHaveValue(
    expected,
  );
  await expect(
    page.getByText("Existing native Load Out required.", { exact: true }),
  ).toBeVisible();
  assert.deepEqual(
    (await state()).loadouts,
    beforeHandoff.loadouts,
    "Opening the handoff cannot place or duplicate fixtures",
  );
  await snap("08-vision-pro-handoff");
  await page.setViewportSize({ width: 390, height: 844 });
  assert.equal(
    await page.evaluate(
      () => document.documentElement.scrollWidth > innerWidth + 1,
    ),
    false,
  );
  await snap("09-vision-pro-handoff-mobile");
  await page.setViewportSize({ width: 1440, height: 1050 });
  await page.getByRole("button", { name: "Close dialog", exact: true }).click();
  checks += 4;
  await snap("04-load-out-inventory");
  await click("2 · Placement");
  for (let i = 0; i < 3; i++) {
    await page
      .getByRole("button", { name: "Edit position", exact: true })
      .nth(i)
      .click();
    await page.getByLabel("X (m)", { exact: true }).fill(String((i - 1) * 3));
    await page.getByLabel("Y (m)", { exact: true }).fill("3");
    await page.getByLabel("Z (m)", { exact: true }).fill("2");
    await page.getByRole("button", { name: /Save placement for/ }).click();
    await expect(page.getByRole("dialog")).toHaveCount(0);
  }
  await page.getByRole("checkbox", { name: /I reviewed/ }).click();
  await expect(
    page.getByRole("checkbox", { name: /I reviewed/ }),
  ).toBeChecked();
  await snap("05-placement");
  await click("3 · Patch");
  for (let i = 0; i < 3; i++) {
    await page
      .getByLabel("Address", { exact: true })
      .nth(i)
      .fill(String(i * 8 + 1));
    await page
      .getByRole("button", { name: "Save patch", exact: true })
      .nth(i)
      .click();
    await expect
      .poll(async () => Object.keys((await state()).loadouts[0].patch).length)
      .toBe(i + 1);
  }
  await click("4 · Review");
  await expect(
    page.getByRole("heading", { name: "Prepared for review", exact: true }),
  ).toBeVisible();
  checks++;
  await click("Duplicate Load Out");
  await page.getByLabel("Load Out name").fill("Glasshouse · alternate");
  await page
    .getByRole("dialog")
    .getByRole("button", { name: "Duplicate Load Out", exact: true })
    .click();
  await expect(page.getByRole("dialog")).toHaveCount(0);
  assert.equal((await state()).units.length, 3);
  assert.equal((await state()).loadouts.length, 3);
  assert.equal((await state()).loadouts[2].tourId, "");
  checks++;
  await page.reload();
  await expect(
    page.getByRole("heading", { name: "Glasshouse · alternate" }),
  ).toBeVisible();
  checks++;
  await nav("Overview");
  await snap("01-overview");
  await nav("Scanned venues");
  await snap("02-scanned-venues");
  await nav("Tours");
  await page.getByRole("button", { name: /Afterglow · Fall Tour/ }).click();
  await click("Edit base inventory");
  await page
    .getByRole("dialog")
    .getByRole("checkbox", { name: /Wash 02/ })
    .uncheck();
  await click("Save inventory selection");
  await expect(page.getByRole("dialog")).toHaveCount(0);
  await page
    .getByRole("button", { name: /The Glasshouse Glasshouse · evening/ })
    .click();
  await click("Review base changes");
  await click("Apply reviewed base inventory");
  await expect(page.getByRole("dialog")).toHaveCount(0);
  assert.equal((await state()).loadouts[0].extraUnitIds.length, 2);
  assert.equal((await state()).loadouts[1].baseUnitIds.length, 2);
  checks++;
  // All product sections, desktop and phone: actual pages, no inherited design-study navigation.
  for (const width of [1440, 390]) {
    await page.setViewportSize({ width, height: width === 390 ? 844 : 1050 });
    for (const label of [
      "Overview",
      "Scanned venues",
      "Load Outs",
      "Fixture inventory",
      "Tours",
      "Programming",
      "Rehearsal & live",
      "Files",
      "Activity",
      "Team & access",
      "Workspace settings",
      "Plan & billing",
    ]) {
      await nav(label);
      await expect(page.locator("main h1")).toBeVisible();
      assert.equal(
        await page.evaluate(
          () => document.documentElement.scrollWidth > innerWidth + 1,
        ),
        false,
        `${label} overflow at ${width}`,
      );
      checks++;
    }
    await nav("Load Outs");
    await page.getByRole("button", { name: /Glasshouse · evening/ }).click();
    for (const tab of [
      "1 · Inventory",
      "2 · Placement",
      "3 · Patch",
      "4 · Review",
    ]) {
      await click(tab);
      assert.equal(
        await page.evaluate(
          () => document.documentElement.scrollWidth > innerWidth + 1,
        ),
        false,
        `${tab} overflow at ${width}`,
      );
      checks++;
    }
    if (width === 390) {
      await click("1 · Inventory");
      await snap("06-mobile-load-out");
    }
  }
  await page.setViewportSize({ width: 1440, height: 1050 });
  await click("4 · Review");
  await click("Programming preview");
  await expect(page.getByText(/Programming design preview/)).toBeVisible();
  checks++;
  // Direct links retain the Load Out and isolate preview drafts by its stable ID.
  const current = await state();
  for (const screen of [
    "presets",
    "preset-editor",
    "cues",
    "cue-editor",
    "scripts",
    "script-editor",
    "rehearsal",
    "live",
    "outputs",
    "universe",
    "recovery",
    "library",
    "fixture",
  ]) {
    await page.goto(
      `${base}/?screen=${screen}&loadoutId=${current.loadouts[0].id}`,
    );
    await expect(page.locator("main")).toBeVisible();
    await expect(page.getByText(/Programming design preview/)).toBeVisible();
    checks++;
  }
  await page.goto(`${base}/?screen=new-venue`);
  await expect(
    page.getByRole("heading", { name: "Upload a venue movie", exact: true }),
  ).toBeVisible();
  await expect(
    page.getByRole("button", { name: "From a template" }),
  ).toHaveCount(0);
  checks++;
  await page.goto(`${base}/upload`);
  await expect(
    page.getByRole("heading", { name: /Capture now/ }),
  ).toBeVisible();
  await snap("07-standalone-upload");
  checks++;
  assert.deepEqual(errors, []);
  console.log(
    `${checks} workspace browser checks passed; screenshots: ${output}`,
  );
} finally {
  await browser.close();
}
