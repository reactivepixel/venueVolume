import { chromium, expect } from "@playwright/test";
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { mkdir, readFile, unlink, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { createInterface } from "node:readline";

const root = fileURLToPath(new URL("../../../", import.meta.url));
// Build output is served by the actual intake server, including /upload reloads.
const server = spawn("python3", ["tests/venue_ingest/fixture_server.py"], { cwd: root, stdio: ["ignore", "pipe", "inherit"] });
const lines = createInterface({ input: server.stdout });
const ready = await Promise.race([
  once(lines, "line").then(([line]) => JSON.parse(line)),
  once(server, "exit").then(([code]) => { throw new Error(`Fixture server exited: ${code}`); }),
]);
const base = ready.url;
let browser;
try {
  browser = await chromium.launch({ headless: true, args: ["--no-sandbox"],
    ...(process.env.VV_CHROMIUM_EXECUTABLE ? { executablePath: process.env.VV_CHROMIUM_EXECUTABLE } : {}) });
} catch (error) {
  lines.close();
  const closed = once(server, "exit");
  server.kill("SIGTERM");
  await closed;
  throw error;
}
const page = await browser.newPage({ viewport: { width: 1440, height: 1080 } });
const errors = [];
page.on("pageerror", (error) => errors.push(error.message));
const movie = Buffer.concat([Buffer.from([0, 0, 0, 24]), Buffer.from("ftypqt  "), Buffer.alloc(100)]);
const fixture = (name = "Walkthrough.MOV", buffer = movie) => ({ name, mimeType: "video/quicktime", buffer });
const screenshotDir = `${root}/tmp/venue-upload-review`;
await mkdir(screenshotDir, { recursive: true });
let checks = 0;
async function noOverflow() {
  await page.evaluate(() => document.fonts.ready);
  assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth + 1), false);
  assert.deepEqual(await page.locator(".movie-upload-form, .movie-setup-form").evaluateAll((forms) => forms.flatMap((form) => {
    const bounds = form.getBoundingClientRect();
    return [...form.querySelectorAll("input, label, select")].filter((item) => {
      const rect = item.getBoundingClientRect();
      return rect.right > bounds.right + 1 || rect.left < bounds.left - 1;
    }).map((item) => item.outerHTML.slice(0, 100));
  })), [], "Upload/setup controls must not be clipped inside their panel");
  checks++;
}

try {
  await page.goto(`${base}/upload`);
  await expect(page.getByRole("heading", { name: /Capture now/ })).toBeVisible();
  assert.equal(await page.getByRole("navigation", { name: "Show navigation" }).count(), 0);
  await page.screenshot({ path: `${screenshotDir}/standalone-desktop.png`, fullPage: true });
  await noOverflow();
  await expect(page.getByRole("button", { name: "Upload & process movie" })).toBeDisabled();
  await page.getByLabel("Venue movie", { exact: true }).setInputFiles(fixture("wrong.txt"));
  await expect(page.getByRole("alert")).toContainText("Choose a MOV, MP4, or M4V");
  await page.getByLabel("Venue movie", { exact: true }).setInputFiles(fixture("huge.mov", Buffer.alloc(1024 ** 2 + 1)));
  await expect(page.getByRole("alert")).toContainText("smaller than");
  checks += 3;

  await page.route("**/api/venues", (route) => route.abort());
  await page.reload();
  await expect(page.getByRole("alert")).toContainText("intake is unavailable");
  await page.getByLabel("Venue movie", { exact: true }).setInputFiles(fixture());
  await expect(page.getByRole("button", { name: "Upload & process movie" })).toBeDisabled();
  await page.unroute("**/api/venues");
  await page.getByRole("button", { name: "Reconnect" }).click();
  await expect(page.getByRole("button", { name: "Upload & process movie" })).toBeEnabled();
  await page.getByRole("button", { name: "Upload & process movie" }).click();
  await expect(page).toHaveURL(/\/upload\?venue=/);
  const standaloneId = new URL(page.url()).searchParams.get("venue");
  await expect(page.getByRole("heading", { name: "Splat ready", exact: true })).toBeVisible({ timeout: 12000 });
  await expect(page.getByText("Needs setup", { exact: true })).toBeVisible();
  await page.reload();
  await expect(page.getByRole("heading", { name: "Walkthrough", exact: true })).toBeVisible();
  const downloadEvent = page.waitForEvent("download");
  await page.getByRole("link", { name: "Download venue splat" }).click();
  const download = await downloadEvent;
  assert.match(download.suggestedFilename(), /\.ply$/);
  assert.match((await readFile(await download.path())).toString("ascii", 0, 50), /ply\nformat binary_little_endian/);
  checks += 4;

  // A fresh session sees the same server-backed venue, without localStorage.
  const fresh = await browser.newPage();
  await fresh.goto(`${base}/upload?venue=${standaloneId}`);
  await expect(fresh.getByRole("heading", { name: "Splat ready", exact: true })).toBeVisible();
  await fresh.close();
  await page.getByRole("link", { name: "Open venue setup" }).click();
  await page.getByRole("textbox", { name: "Venue name", exact: true }).fill("The Atrium");
  await page.getByRole("textbox", { name: "City (optional)", exact: true }).fill("Brooklyn");
  await page.getByRole("button", { name: "Import scanned venue" }).click();
  await expect(page.getByText("Imported scan", { exact: true })).toBeVisible();
  await page.getByRole("button", { name: "All scanned venues", exact: true }).click();
  await expect(page.getByRole("button", { name: /The Atrium.*Scan ready/ })).toBeVisible();
  assert.equal((await (await page.request.get(`${base}/api/venues`)).json()).venues.length, 1);
  await page.reload();
  await expect(page.getByRole("button", { name: /The Atrium.*Scan ready/ })).toBeVisible();
  checks += 3;

  await page.getByRole("button", { name: "Upload venue movie", exact: true }).click();
  await page.getByRole("textbox", { name: /Venue name \(optional\)/ }).fill("Mercury movie venue");
  await page.getByLabel("Venue movie", { exact: true }).setInputFiles(fixture());
  await page.getByRole("button", { name: "Upload & process movie", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Splat ready", exact: true })).toBeVisible({ timeout: 12000 });
  await expect(page.getByText("Needs setup", { exact: true })).toBeVisible();
  const directId = new URL(page.url()).searchParams.get("venueId");
  assert.notEqual(directId, standaloneId, "Same filename is allowed for different venues");
  const direct = await (await page.request.get(`${base}/api/venues/${directId}`)).json();
  assert.equal(direct.show, "");
  assert.equal(direct.template, "");
  checks += 2;

  // Complete an interrupted reservation, fail the GPU job, then retry the
  // original stored movie; retry must not create another venue or upload.
  const reservation = await (await page.request.post(`${base}/api/venues`, { data: {
    idempotencyKey: crypto.randomUUID(), filename: "Retry.mov", size: movie.length,
  } })).json();
  await writeFile(`${ready.dataDir}/${reservation.id}/test-mode`, "fail");
  await page.goto(`${base}/upload?venue=${reservation.id}`);
  await page.getByLabel("Venue movie", { exact: true }).setInputFiles(fixture("Retry.mov"));
  await page.getByRole("button", { name: "Retry upload", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Processing failed", exact: true })).toBeVisible({ timeout: 12000 });
  await unlink(`${ready.dataDir}/${reservation.id}/test-mode`);
  await page.getByRole("button", { name: "Retry processing", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Splat ready", exact: true })).toBeVisible({ timeout: 12000 });
  const retried = await (await page.request.get(`${base}/api/venues/${reservation.id}`)).json();
  assert.equal(retried.attempts, 2);
  assert.equal((await (await page.request.get(`${base}/api/venues`)).json()).venues.length, 3);
  checks += 2;

  // A rejected body retains the reservation in the URL. Reloading can resume
  // the same venue rather than silently creating a duplicate intake record.
  await page.goto(`${base}/upload`);
  await page.getByLabel("Venue movie", { exact: true }).setInputFiles(fixture("Recover.mov", Buffer.alloc(movie.length, 120)));
  await page.getByRole("button", { name: "Upload & process movie" }).click();
  await expect(page.getByRole("alert")).toContainText("not a recognizable");
  await expect(page).toHaveURL(/\/upload\?venue=/);
  const recoverId = new URL(page.url()).searchParams.get("venue");
  await page.reload();
  await page.getByLabel("Venue movie", { exact: true }).setInputFiles(fixture("Recover.mov"));
  await page.getByRole("button", { name: "Retry upload" }).click();
  await expect(page.getByRole("heading", { name: "Splat ready", exact: true })).toBeVisible({ timeout: 12000 });
  assert.equal(new URL(page.url()).searchParams.get("venue"), recoverId);
  assert.equal((await (await page.request.get(`${base}/api/venues`)).json()).venues.length, 4);
  checks += 2;

  // A resumed, throttled upload must survive status polling changing the
  // server record from awaiting_upload to uploading while XHR is in flight.
  const slowMovie = Buffer.concat([movie, Buffer.alloc(8192 - movie.length)]);
  const slow = await (await page.request.post(`${base}/api/venues`, { data: {
    idempotencyKey: crypto.randomUUID(), filename: "Slow.mov", size: slowMovie.length,
  } })).json();
  await page.goto(`${base}/upload?venue=${slow.id}`);
  const network = await page.context().newCDPSession(page);
  await network.send("Network.enable");
  await network.send("Network.emulateNetworkConditions", { offline: false, latency: 0, downloadThroughput: -1, uploadThroughput: 1024 });
  try {
    await page.getByLabel("Venue movie", { exact: true }).setInputFiles(fixture("Slow.mov", slowMovie));
    await page.getByRole("button", { name: "Retry upload" }).click();
    await expect(page.getByRole("heading", { name: "Uploading movie", exact: true })).toBeVisible({ timeout: 10000 });
    await expect(page.getByRole("progressbar", { name: "Movie upload progress" })).toBeVisible();
    await expect(page.getByRole("heading", { name: "Splat ready", exact: true })).toBeVisible({ timeout: 25000 });
  } finally {
    await network.send("Network.emulateNetworkConditions", { offline: false, latency: 0, downloadThroughput: -1, uploadThroughput: -1 });
    await network.detach();
  }
  assert.equal((await (await page.request.get(`${base}/api/venues/${slow.id}`)).json()).size, slowMovie.length);
  checks++;

  await page.goto(`${base}/?screen=venues`);
  await expect(page.getByRole("button", { name: /Retry.*Splat ready/ })).toBeVisible();
  await page.screenshot({ path: `${screenshotDir}/venue-inbox-desktop.png`, fullPage: true });
  await noOverflow();
  await page.setViewportSize({ width: 390, height: 844 });
  await noOverflow();
  await page.screenshot({ path: `${screenshotDir}/venue-inbox-mobile.png`, fullPage: true });
  await page.goto(`${base}/upload`);
  await noOverflow();
  await page.screenshot({ path: `${screenshotDir}/standalone-mobile.png`, fullPage: true });
  await page.goto(`${base}/?screen=new-venue`);
  await noOverflow();
  await page.screenshot({ path: `${screenshotDir}/workspace-upload-mobile.png`, fullPage: true });
  await page.goto(`${base}/?screen=venue-detail&venueId=${reservation.id}`);
  await expect(page.getByRole("button", { name: "Import scanned venue" })).toBeVisible();
  await noOverflow();
  await page.screenshot({ path: `${screenshotDir}/venue-setup-mobile.png`, fullPage: true });
  assert.deepEqual(errors, [], "Browser runtime errors");
  console.log(`PASS: ${checks} venue upload, processing, import, persistence, recovery and layout checks.`);
} finally {
  await browser.close();
  lines.close();
  const closed = once(server, "exit");
  server.kill("SIGTERM");
  await closed;
}
