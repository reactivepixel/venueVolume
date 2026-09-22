import { chromium, expect } from "@playwright/test";
import assert from "node:assert/strict";
import { resolve } from "node:path";
const base = process.env.VV_BASE_URL || "http://127.0.0.1:5173";
const browser = await chromium.launch({
  headless: true,
  args: ["--no-sandbox"],
});
const context = await browser.newContext({
  viewport: { width: 1600, height: 1050 },
});
const page = await context.newPage();
const errors = [];
context.on("page", (p) => p.on("pageerror", (e) => errors.push(e.message)));
page.on("pageerror", (e) => errors.push(e.message));
try {
  await page.goto(`${base}/?screen=live&mode=hifi&state=ready`);
  await expect(
    page.getByRole("heading", { name: "The Glasshouse / Live console" }),
  ).toBeVisible();
  const sectionSurfaces = await page.locator("[data-desk-zone]").evaluateAll(
    (zones) => zones.map((zone) => getComputedStyle(zone).backgroundColor),
  );
  assert.equal(new Set(sectionSurfaces).size, 6, "Each control section has a distinct surface color");
  await page.getByRole("button", { name: "Upstage wash", exact: true }).click();
  await expect(page.locator('[data-desk-zone="stage"]')).toHaveAttribute("data-zone-active", "true");
  await expect(page.locator(".desk-zone-readout")).toHaveText("Control focus · Stage / fixtures");
  await expect(page.getByTestId("selection-count")).toHaveText("4 / 8");
  await page
    .getByRole("slider", { name: "Selected intensity", exact: true })
    .fill("40");
  await expect(
    page.getByRole("slider", { name: "Selected intensity", exact: true }),
  ).toHaveValue("40");
  await expect(page.locator('[data-desk-zone="programmer"]')).toHaveAttribute("data-zone-active", "true");
  await page.getByRole("slider", { name: "Upstage wash master", exact: true }).focus();
  await expect(page.locator('[data-desk-zone="groups"]')).toHaveAttribute("data-zone-active", "true");
  await expect(page.locator('[data-zone-active="true"]')).toHaveCount(1);
  await page
    .getByRole("button", { name: "Arm simulation", exact: true })
    .click();
  await page.getByRole("button", { name: "Next", exact: true }).click();
  await expect(page.locator(".playback-summary h2")).toContainText("Q01");
  await page
    .getByRole("button", { name: "Inspect Q02 Into the blue", exact: true })
    .click();
  await expect(page.locator(".cue-details")).toContainText("Reactive targets");
  await expect(page.locator(".playback-summary h2")).toContainText("Q01");
  await page.getByRole("checkbox", { name: "Enable MIDI triggers" }).click();
  await expect(
    page.getByRole("checkbox", { name: "Enable MIDI triggers" }),
  ).toBeChecked();
  await page
    .getByRole("button", { name: "Test Q02 trigger", exact: true })
    .click();
  await expect(page.locator(".playback-summary h2")).toContainText("Q02");
  await expect(page.locator(".desk-cue-row.fired")).toHaveCount(2);
  await page.getByRole("button", { name: "Next", exact: true }).click();
  await expect(page.locator(".playback-summary h2")).toContainText("Q03");
  await expect(page.locator(".desk-workspace .playback-panel")).toHaveCount(0);
  await expect(page.locator(".playback-dock .desk-cue-row")).toHaveCount(6);
  await page.getByRole("button", { name: "Back", exact: true }).click();
  await expect(page.locator(".playback-summary h2")).toContainText("Q02");
  await expect(page.locator("dialog")).toHaveCount(0);
  await page.getByRole("button", { name: "Next", exact: true }).click();
  await expect(page.locator(".playback-summary h2")).toContainText("Q03");
  await page
    .getByRole("button", { name: "Restart 01 · Into the blue", exact: true })
    .click();
  await page
    .getByRole("button", { name: "Restart & call cue", exact: true })
    .click();
  await expect(page.locator(".playback-summary h2")).toContainText("Q02");
  await expect(page.locator(".desk-cue-row.fired")).toHaveCount(2);
  await page
    .getByRole("button", { name: "Inspect Q03 First light", exact: true })
    .click();
  await page
    .getByRole("button", { name: "Test Q03 trigger", exact: true })
    .click();
  await expect(page.locator(".playback-summary h2")).toContainText("Q03");
  await page.getByRole("button", { name: "Hold", exact: true }).click();
  await expect(
    page.getByRole("button", { name: "Next", exact: true }),
  ).toBeDisabled();
  await expect(page.getByRole("button", { name: "Back", exact: true })).toBeDisabled();
  await expect(page.locator(".playback-summary h2")).toContainText("Q03");
  await page.getByRole("button", { name: "Play", exact: true }).click();
  await expect(page.locator(".playback-summary h2")).toContainText("Q03");
  await page.getByRole("button", { name: "Blackout", exact: true }).click();
  await expect(
    page.getByRole("button", { name: "Next", exact: true }),
  ).toBeDisabled();
  await page
    .getByRole("button", { name: "Restore output", exact: true })
    .click();
  const popupPromise = context.waitForEvent("page");
  await page
    .getByRole("button", { name: "Pop out console", exact: true })
    .click();
  const popup = await popupPromise;
  await popup.waitForLoadState();
  await expect(popup.locator(".playback-summary h2")).toContainText("Q03");
  await expect(popup.locator(".sidebar")).toBeHidden();
  const editorPromise = context.waitForEvent("page");
  await popup.getByRole("button", { name: "Preflight", exact: true }).click();
  const editor = await editorPromise;
  await editor.waitForLoadState();
  assert.equal(new URL(editor.url()).searchParams.get("screen"), "preflight");
  assert.equal(new URL(popup.url()).searchParams.get("screen"), "live");
  await expect(popup.locator(".playback-summary h2")).toContainText("Q03");
  await editor.close();
  assert.equal(
    await popup.evaluate(
      () => document.documentElement.scrollHeight <= innerHeight + 1,
    ),
    true,
    "Wide popout must keep timeline and transport inside the viewport",
  );
  await popup
    .getByRole("slider", { name: "Grand master", exact: true })
    .fill("55");
  await expect(
    page.getByRole("slider", { name: "Grand master", exact: true }),
  ).toHaveValue("55");
  const navigationCount = { count: 0 };
  popup.on("framenavigated", () => navigationCount.count++);
  await page.locator('.workflow-modes [data-phase="programming"]').click();
  // Use a direct editor URL if the workflow picker changes in a future design pass.
  if (!page.url().includes("preset-editor"))
    await page.goto(`${base}/?screen=preset-editor`);
  await page
    .getByRole("button", { name: "The Glasshouse", exact: true })
    .click();
  await page
    .getByRole("slider", { name: "Preset intensity", exact: true })
    .fill("23");
  await expect(popup.locator(".live-update-banner")).toBeVisible();
  await popup
    .getByRole("button", { name: "Review & apply", exact: true })
    .click();
  await popup
    .getByRole("button", { name: "Apply to future cues", exact: true })
    .click();
  await expect(popup.locator(".live-update-banner")).toHaveCount(0);
  assert.equal(
    navigationCount.count,
    0,
    "Popout must not reload for editor changes",
  );
  await page.close();
  await popup.getByRole("button", { name: "Next", exact: true }).click();
  await expect(popup.locator(".playback-summary h2")).toContainText("Q04");
  await popup.getByRole("button", { name: "Whole venue", exact: true }).click();
  await expect(popup.getByTestId("selection-count")).toHaveText("8 / 8");
  await popup
    .getByRole("slider", { name: "Selected intensity", exact: true })
    .fill("70");
  await expect(popup.locator(".rig-fixture.manual")).toHaveCount(8);
  await popup
    .getByRole("button", { name: "Release selected to cue", exact: true })
    .click();
  await expect(popup.locator(".rig-fixture.manual")).toHaveCount(0);
  await popup.getByRole("slider", { name: "Selected intensity", exact: true }).focus();
  await popup.evaluate(()=>document.querySelectorAll('.desk-inspector,.stage-panel,.cue-list-scroll').forEach(el=>el.scrollTop=0));
  await popup.screenshot({
    path: resolve(
      "../../assets/design/venue-volume/high-fidelity/live-popout.png",
    ),
    fullPage: true,
  });
  await popup
    .getByRole("button", { name: "Inspect Q04 Still / moving", exact: true })
    .click();
  await expect(popup.locator(".cue-details")).toContainText("Reactive targets");
  await popup.evaluate(()=>document.querySelector('.desk-inspector').scrollTop=0);
  await popup.screenshot({
    path: resolve(
      "../../assets/design/venue-volume/high-fidelity/live-cue-inspector.png",
    ),
    fullPage: true,
  });
  await popup.getByRole("button", { name: "House", exact: true }).click();
  await expect(popup.locator(".playback-summary h2")).toContainText("Q01");
  await expect(popup.getByRole("button", { name: "Back", exact: true })).toBeDisabled();
  for (const cue of ["Q02", "Q03", "Q04"]) {
    await popup.getByRole("button", { name: "Next", exact: true }).click();
    await expect(popup.locator(".playback-summary h2")).toContainText(cue);
  }
  await popup
    .getByRole("button", { name: "Edit MIDI mapping", exact: true })
    .click();
  await popup
    .getByRole("spinbutton", { name: "MIDI number", exact: true })
    .fill("72");
  await popup.screenshot({
    path: resolve(
      "../../assets/design/venue-volume/dialogs/live-midi-mapping.png",
    ),
    fullPage: true,
  });
  await popup
    .getByRole("button", { name: "Save venue MIDI mapping", exact: true })
    .click();
  await expect(popup.locator(".live-update-banner")).toBeVisible();
  await popup
    .getByRole("button", { name: "Review & apply", exact: true })
    .click();
  await popup
    .getByRole("button", { name: "Apply to future cues", exact: true })
    .click();
  await expect(popup.locator(".cue-trigger-detail")).toContainText("NOTE 72");
  const sibling = await context.newPage();
  await sibling.goto(`${base}/?screen=live&venue=Mercury%20Hall&popout=1`);
  await expect(sibling.locator(".playback-summary h2")).toHaveText("Standby");
  await expect(
    sibling.getByRole("slider", { name: "Grand master", exact: true }),
  ).toHaveValue("100");
  await sibling.close();
  await popup.setViewportSize({ width: 1024, height: 768 });
  assert.equal(
    await popup.evaluate(
      () => document.documentElement.scrollWidth > innerWidth + 1,
    ),
    false,
  );
  await popup.screenshot({
    path: resolve(
      "../../assets/design/venue-volume/mobile/live-touch-tablet.png",
    ),
    fullPage: true,
  });
  await popup.setViewportSize({ width: 390, height: 844 });
  assert.equal(
    await popup.evaluate(
      () => document.documentElement.scrollWidth > innerWidth + 1,
    ),
    false,
  );
  assert.deepEqual(errors, []);
  console.log(
    "PASS: touch selection, manual levels, MIDI calls, song restart/replay, history, hold/blackout, two-window sync, hot editor updates without reload, parent-close continuity, and responsive popout.",
  );
} finally {
  await browser.close();
}
