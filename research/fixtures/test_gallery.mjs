import { chromium } from '../../apps/design-studio/node_modules/@playwright/test/index.mjs';
import assert from 'node:assert/strict';
import { access, readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
const url=new URL('../../assets/fixtures/research/catalog-preview.html',import.meta.url);
const expected=JSON.parse(await readFile(new URL('../../assets/fixtures/research/catalog-validation.json',import.meta.url),'utf8')).fixture_count;
const browser=await chromium.launch({headless:true,executablePath:process.env.VV_CHROMIUM_PATH||'/usr/bin/chromium',args:['--no-sandbox']});
const page=await browser.newPage({viewport:{width:1440,height:1000}});const errors=[];
page.on('pageerror',e=>errors.push(e.message));
try {
 await page.goto(url.href);assert.equal(await page.locator('article').count(),expected);
 const links=await page.locator('a').evaluateAll(as=>as.map(a=>a.href));
 for(const link of links)if(link.startsWith('file:'))await access(fileURLToPath(link));
 await page.selectOption('#batch','2');assert.equal(await page.locator('article').count(),12);
 await page.selectOption('#maker','GLP');assert.equal(await page.locator('article').count(),2);
 await page.fill('#search','Maxx');assert.equal(await page.locator('article').count(),1);
 for(const view of ['front','side','rear','three-quarter']){
  await page.selectOption('#view',view);await page.locator('article img').evaluate(img=>img.decode());
  assert.ok((await page.locator('article img').getAttribute('src')).endsWith(view+'.png'));
 }
 await page.fill('#search','');await page.selectOption('#maker','');await page.selectOption('#batch','');
 await page.screenshot({path:fileURLToPath(new URL('../../assets/fixtures/research/gallery-desktop.png',import.meta.url))});
 await page.setViewportSize({width:390,height:844});
 assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1),false);
 await page.screenshot({path:fileURLToPath(new URL('../../assets/fixtures/research/gallery-mobile.png',import.meta.url))});
 assert.deepEqual(errors,[]);
 await writeFile(new URL('../../assets/fixtures/research/gallery-validation.json',import.meta.url),JSON.stringify({passed:true,fixture_count:expected,local_links_checked:links.filter(l=>l.startsWith('file:')).length,checks:['All cards rendered','Every local asset link resolves','Batch and manufacturer filters','Search','Four view selections and decoded previews','No mobile overflow','No JavaScript errors']},null,2)+'\n');
 console.log('Gallery checks passed');
} finally {await browser.close()}
