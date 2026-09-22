import { chromium, expect } from "@playwright/test";
import assert from "node:assert/strict";
import { screens } from "../src/catalog.js";
const base = process.env.VV_BASE_URL || "http://127.0.0.1:5173";
const browser = await chromium.launch({
  headless: true,
  args: ["--no-sandbox"],
});
const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
const errors = [];
page.on("pageerror", (e) => errors.push(e.message));
page.on("console", (m) => {
  if (m.type() === "error" && !m.text().includes("net::ERR"))
    errors.push(m.text());
});
let checks = 0;
async function navigate(screen, mode = "hifi", state = "ready") {
  await page.goto(`${base}/?screen=${screen}&mode=${mode}&state=${state}`);
  await page.locator("main").waitFor();
  await page.evaluate(() => document.fonts.ready);
}
try {
  for (const mode of ["wire", "hifi"])
    for (const s of screens) {
      await navigate(s.id, mode);
      assert.ok(
        await page.locator("main h1").count(),
        `Missing title: ${mode}/${s.id}`,
      );
      assert.ok(
        await page.locator("main").innerText(),
        `Empty screen: ${s.id}`,
      );
      const overflow = await page.evaluate(
        () => document.documentElement.scrollWidth > innerWidth + 1,
      );
      assert.equal(overflow, false, `Desktop page overflow: ${mode}/${s.id}`);
      checks++;
    }
  await page.setViewportSize({ width: 390, height: 844 });
  for (const s of screens) {
    await navigate(s.id);
    assert.equal(
      await page.evaluate(
        () => document.documentElement.scrollWidth > innerWidth + 1,
      ),
      false,
      `Mobile overflow: ${s.id}`,
    );
    checks++;
  }
  await page.setViewportSize({ width: 1440, height: 1000 });
  await navigate("overview");
  await page.getByRole("button", { name: "35 screens", exact: true }).click();
  assert.equal(
    await page.locator(".screen-gallery section button").count(),
    35,
  );
  await page
    .locator(".screen-gallery")
    .getByRole("button", { name: "21 Cue library F11" })
    .click();
  assert.match(await page.locator("main h1").innerText(), /moment/);
  checks++;
  for (const state of ["empty", "loading", "error", "read-only"]) {
    await navigate("overview", "hifi", state);
    assert.ok((await page.locator("main").innerText()).length > 30);
    checks++;
  }
  await page
    .getByRole("combobox", { name: "Review state" })
    .selectOption("error");
  await page.getByRole("button", { name: "Retry", exact: true }).click();
  assert.match(await page.locator("main h1").innerText(), /Afterglow/);
  checks++;
  await navigate("preset-editor");
  await page
    .getByRole("button", { name: "The Glasshouse", exact: true })
    .click();
  assert.equal(
    await page.getByRole("slider", { name: "Preset intensity" }).inputValue(),
    "60",
  );
  await page.getByRole("slider", { name: "Preset intensity" }).fill("0");
  assert.match(
    await page.locator(".parameter-heading").innerText(),
    /Venue override/,
  );
  await page.getByRole("button", { name: /Reset to show default/ }).click();
  await expect(
    page.getByRole("slider", { name: "Preset intensity" }),
  ).toHaveValue("75");
  await page.reload();
  await page
    .getByRole("button", { name: "The Glasshouse", exact: true })
    .click();
  await expect(
    page.getByRole("slider", { name: "Preset intensity" }),
  ).toHaveValue("75");
  checks++;
  await navigate("patch");
  await page
    .getByRole("spinbutton", { name: "FX-002 address", exact: true })
    .fill("1");
  assert.match(await page.getByRole("alert").innerText(), /overlaps/);
  await navigate("preflight");
  assert.equal(
    await page
      .getByRole("button", { name: "Start rehearsal", exact: true })
      .isDisabled(),
    true,
  );
  await navigate("patch");
  await page
    .getByRole("spinbutton", { name: "FX-002 address", exact: true })
    .fill("9");
  await expect(page.getByRole("alert")).toHaveCount(0);
  checks++;
  await navigate("script-editor");
  const before = await page.locator(".script-slot").first().innerText();
  await page
    .getByRole("button", { name: "Move House open down", exact: true })
    .click();
  await expect
    .poll(() => page.locator(".script-slot").first().innerText())
    .not.toBe(before);
  await page.getByRole("button", { name: "Add cue", exact: true }).click();
  await page.locator("dialog select").selectOption("Q02");
  await page
    .getByRole("button", { name: "Add to script", exact: true })
    .click();
  await expect(page.locator(".script-slot")).toHaveCount(7);
  checks++;
  await navigate("live");
  const go = page.getByRole("button", { name: "Next", exact: true });
  assert.equal(await go.isDisabled(), true);
  await page
    .getByRole("button", { name: "Arm simulation", exact: true })
    .click();
  const old = await page.locator(".playback-summary h2").innerText();
  await go.click();
  await expect(page.locator(".playback-summary h2")).not.toHaveText(old);
  await page.getByRole("button", { name: "Hold", exact: true }).click();
  await expect(go).toBeDisabled();
  await page.getByRole("button", { name: "Play", exact: true }).click();
  await page.getByRole("button", { name: "Blackout", exact: true }).click();
  await expect(go).toBeDisabled();
  await page
    .getByRole("button", { name: "Restore output", exact: true })
    .click();
  await expect(go).toBeEnabled();
  checks++;
  await page.getByRole("button", { name: "Connections", exact: true }).click();
  await page
    .getByRole("button", { name: "Simulate disconnect", exact: true })
    .click();
  await page.getByRole("button", { name: "Live console", exact: true }).click();
  await expect(page.getByRole("button", { name: "Arm simulation", exact: true })).toBeDisabled();
  checks++;
  await navigate("new-show");
  await page
    .getByRole("textbox", { name: "Show name", exact: true })
    .fill("Browser test production");
  await page.getByRole("button", { name: "Create show", exact: true }).click();
  await expect(page.locator("main h1")).toHaveText("Browser test production");
  checks++;
  assert.deepEqual(errors, [], "Browser console errors");
  console.log(
    `PASS: ${checks} screen, layout and interaction checks; no browser errors.`,
  );
} finally {
  await browser.close();
}
