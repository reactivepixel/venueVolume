import { chromium } from "@playwright/test";
import { mkdir, writeFile } from "node:fs/promises";
import { resolve } from "node:path";
import { screens } from "../src/catalog.js";
const base = process.env.VV_BASE_URL || "http://127.0.0.1:5173";
const output = resolve("../../assets/design/venue-volume");
await mkdir(output, { recursive: true });
for (const dir of [
  "wireframes",
  "high-fidelity",
  "mobile",
  "states",
  "dialogs",
])
  await mkdir(resolve(output, dir), { recursive: true });
const browser = await chromium.launch({
  headless: true,
  args: ["--no-sandbox"],
});
const page = await browser.newPage({
  viewport: { width: 1440, height: 1040 },
  deviceScaleFactor: 1,
});
const errors = [];
page.on("pageerror", (e) => errors.push(e.message));
async function capture(id, mode, path, state = "ready") {
  await page.goto(`${base}/?screen=${id}&mode=${mode}&state=${state}`);
  await page.locator("main").waitFor();
  await page.evaluate(() => document.fonts.ready);
  await page.screenshot({ path: resolve(output, path), fullPage: true });
}
for (const [mode, dir] of [
  ["wire", "wireframes"],
  ["hifi", "high-fidelity"],
]) {
  for (const s of screens)
    await capture(s.id, mode, `${dir}/${s.number}-${s.id}.png`);
  console.log(`Exported ${screens.length} ${dir} screens.`);
}
for (const state of ["empty", "loading", "error", "read-only"])
  await capture("overview", "hifi", `states/${state}.png`, state);
for (const [id, label] of [
  ["templates", "New configuration"],
  ["presets", "Create preset"],
  ["cues", "Create cue"],
  ["scripts", "Create script"],
  ["script-editor", "Add cue"],
  ["team", "Invite teammate"],
  ["outputs", "Pair bridge"],
  ["settings", "Review archive"],
  ["overrides", "Review template update"],
]) {
  await page.goto(`${base}/?screen=${id}&mode=hifi`);
  await page.evaluate(() => document.fonts.ready);
  await page.getByRole("button", { name: label, exact: true }).click();
  await page.locator("dialog").waitFor();
  await page.screenshot({
    path: resolve(output, `dialogs/${id}.png`),
    fullPage: true,
  });
}
await page.setViewportSize({ width: 390, height: 844 });
for (const id of [
  "shows",
  "overview",
  "venue-detail",
  "preset-editor",
  "script-editor",
  "live",
  "patch",
  "outputs",
])
  await capture(id, "hifi", `mobile/${id}.png`);
const esc = (s) =>
  s.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll('"', "&quot;");
const css = `*{box-sizing:border-box}body{margin:0;background:#f4f5ee;color:#25311f;font:14px system-ui,sans-serif}header{padding:48px 5%;border-bottom:1px solid #dbe1ce;background:#e9efda}header small{letter-spacing:3px;color:#7f9463}h1{font-size:42px;letter-spacing:-1.7px;font-weight:550;margin:18px 0 10px}p{line-height:1.7;color:#7e8b70}nav{display:flex;gap:10px;flex-wrap:wrap;padding:22px 5%;position:sticky;top:0;background:#f4f5eef5;z-index:2;border-bottom:1px solid #dbe1ce}button,input,select{font:inherit;padding:10px 14px;border:1px solid #ccd6bc;background:white;color:#50663e;border-radius:5px}button{cursor:pointer}button.active{background:#3e542f;color:#f0f6e6}input{margin-left:auto}main{padding:28px 5%}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:24px}article{border:1px solid #dce3d0;border-radius:6px;overflow:hidden;background:#fffef8}article a{display:block;background:#e6ebdc;height:260px;overflow:hidden}article img{width:100%;display:block}article>div{padding:18px}article small{color:#899e70;font-size:10px;letter-spacing:1px}h2{font-size:15px;font-weight:600}article p{font-size:11px;margin-bottom:0}footer{padding:25px 5%;font-size:11px;color:#899775}a{color:#536e3d}.supplement{display:flex;gap:15px;flex-wrap:wrap;margin:25px 0;font-size:12px}.supplement a{padding:8px 0}body.contact nav,body.contact .supplement,body.contact footer{display:none}body.contact header{padding:28px 35px}body.contact h1{font-size:28px;margin:12px 0}body.contact header p{font-size:11px}body.contact main{padding:20px 35px}body.contact .grid{grid-template-columns:repeat(5,1fr);gap:15px}body.contact article a{height:192px}body.contact article>div{padding:10px}body.contact article p{display:none}body.contact h2{font-size:11px;margin:5px 0}body.contact article small{font-size:8px}@media(max-width:900px){.grid{grid-template-columns:repeat(2,1fr)}article a{height:180px}}@media(max-width:550px){.grid{grid-template-columns:1fr}h1{font-size:32px}input{margin-left:0;width:100%}}`;
const supplements = `<div class="supplement"><strong>Additional states & flows:</strong>${["empty", "loading", "error", "read-only"].map((s) => `<a href="states/${s}.png">${s}</a>`).join("")}${["templates", "presets", "cues", "scripts", "script-editor", "team", "outputs", "settings", "overrides"].map((s) => `<a href="dialogs/${s}.png">${s} dialog</a>`).join("")}<a href="high-fidelity/live-popout.png">Touch pop-out</a><a href="high-fidelity/live-cue-inspector.png">Cue targets</a><a href="dialogs/live-midi-mapping.png">Venue MIDI mapping</a><a href="mobile/live-touch-tablet.png">Touch tablet</a><a href="mobile/live.png">Mobile console</a><a href="mobile/overview.png">Mobile overview</a></div>`;
const cards = screens
  .map(
    (s) =>
      `<article data-section="${s.section}" data-search="${esc(`${s.title} ${s.feature} ${s.section}`.toLowerCase())}"><a href="high-fidelity/${s.number}-${s.id}.png" target="_blank"><img loading="eager" alt="${esc(s.title)} mockup" src="high-fidelity/${s.number}-${s.id}.png"></a><div><small>${s.number} / ${s.section.toUpperCase()} / ${s.feature}</small><h2>${esc(s.title)}</h2><p>${esc(s.purpose)}</p></div></article>`,
  )
  .join("");
const html = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Venue Volume · Screen gallery</title><style>${css}</style></head><body><header><small>VENUE VOLUME / DESIGN STUDY 01</small><h1>One show. Every screen.</h1><p>35 screens, from workspace to encore. Compare the structural wireframes with their refined product direction.<br>These are UI mockups. All production data, connectivity, and output are simulated.</p></header><nav><button data-mode="wireframes">01 Wireframes</button><button class="active" data-mode="high-fidelity">02 High fidelity</button><select aria-label="Section"><option>All sections</option>${[...new Set(screens.map((s) => s.section))].map((s) => `<option>${s}</option>`).join("")}</select><input aria-label="Search screens" placeholder="Find a screen or feature…"></nav><main><div class="grid">${cards}</div>${supplements}</main><footer>Rendered from the React design studio · 1440 px desktop · Open any image at full size. Interactive review: run apps/design-studio and open http://localhost:5173.</footer><script>const cards=[...document.querySelectorAll('article')];window.setMode=(mode)=>{document.querySelectorAll('[data-mode]').forEach(b=>b.classList.toggle('active',b.dataset.mode===mode));cards.forEach(c=>{const img=c.querySelector('img');img.src=img.getAttribute('src').replace(/^(wireframes|high-fidelity)/,mode);c.querySelector('a').href=img.getAttribute('src')});};document.querySelectorAll('[data-mode]').forEach(b=>b.onclick=()=>setMode(b.dataset.mode));function filter(){const q=document.querySelector('input').value.toLowerCase(),s=document.querySelector('select').value;cards.forEach(c=>c.hidden=!(c.dataset.search.includes(q)&&(s==='All sections'||s===c.dataset.section)))}document.querySelector('input').oninput=filter;document.querySelector('select').onchange=filter;</script></body></html>`;
await writeFile(resolve(output, "index.html"), html);
await page.setViewportSize({ width: 1700, height: 1200 });
await page.goto(`file://${resolve(output, "index.html")}`);
await page.evaluate(() => document.body.classList.add("contact"));
for (const mode of ["wireframes", "high-fidelity"]) {
  await page.evaluate((mode) => window.setMode(mode), mode);
  await page.evaluate(() =>
    Promise.all(
      [...document.images].map((img) => img.decode().catch(() => {})),
    ),
  );
  await page.screenshot({
    path: resolve(output, `${mode}-contact-sheet.png`),
    fullPage: true,
  });
}
await writeFile(
  resolve(output, "manifest.json"),
  JSON.stringify(
    {
      generatedAt: new Date().toISOString(),
      desktop: { width: 1440, height: 1040 },
      mobile: { width: 390, height: 844 },
      screens,
      desktopCount: 70,
      stateCount: 4,
      dialogCount: 9,
      mobileCount: 8,
      extraLiveViews: [
        "high-fidelity/live-popout.png",
        "high-fidelity/live-cue-inspector.png",
        "dialogs/live-midi-mapping.png",
        "mobile/live-touch-tablet.png",
      ],
      errors,
    },
    null,
    2,
  ),
);
await browser.close();
if (errors.length) throw Error(errors.join("\n"));
console.log(
  `Exported gallery, contact sheets, 70 desktop screens, 4 state examples, 9 dialogs and 8 mobile views to ${output}`,
);
