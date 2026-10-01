import { chromium } from '../../apps/design-studio/node_modules/@playwright/test/index.mjs';
import assert from 'node:assert/strict';
import { readFile, access, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
const root=new URL('../../',import.meta.url),dir=new URL('assets/fixtures/research/',root);
const data=JSON.parse(await readFile(new URL('show-equipment-taxonomy.json',dir),'utf8'));
const leaves=data.categories.filter(c=>c.is_leaf),gaps=leaves.filter(c=>!c.asset_count);
assert.equal(data.summary.asset_count,data.items.length);
assert.equal(data.summary.terminal_categories,leaves.length);
assert.equal(data.summary.unrepresented_categories,gaps.length);
assert.equal(new Set(data.items.map(i=>i.id)).size,data.items.length);
assert.equal(leaves.reduce((sum,c)=>sum+c.asset_count,0),data.items.length);
for(const c of leaves)for(const id of c.asset_ids)assert.equal(data.items.find(i=>i.id===id).category_id,c.id);
const browser=await chromium.launch({headless:true,executablePath:process.env.VV_CHROMIUM_PATH||'/usr/bin/chromium',args:['--no-sandbox']});
const page=await browser.newPage({viewport:{width:1440,height:1100}}),errors=[];page.on('pageerror',e=>errors.push(e.message));
try{
 await page.goto(new URL('show-equipment.html',dir).href);
 assert.equal(await page.locator('article').count(),data.items.length);
 const links=await page.locator('a').evaluateAll(nodes=>nodes.map(n=>n.href));
 for(const link of links)if(link.startsWith('file:'))await access(fileURLToPath(link));
 const represented=leaves.find(c=>c.id==='atmosphere.fog')||leaves.find(c=>c.asset_count);
 await page.locator(`[data-category="${represented.id}"]`).click();assert.equal(await page.locator('article').count(),represented.asset_count);
 for(const view of ['front','side','rear','three-quarter']){await page.selectOption('#view',view);await page.locator('article img').first().evaluate(img=>img.decode())}
 await page.click('#gaps');assert.equal(await page.locator('[data-gap]').count(),gaps.length);
 if(gaps.length){await page.locator('[data-gap]').first().click();assert.equal(await page.locator('article').count(),0);assert.match(await page.locator('#gaplist').innerText(),/No completed representative/)}
 await page.click('#all');await page.fill('#search','ColorSource 20');assert.equal(await page.locator('article').count(),1);
 await page.fill('#search','');await page.selectOption('#maker','ETC');assert.equal(await page.locator('article').count(),data.items.filter(i=>i.manufacturer==='ETC').length);
 await page.selectOption('#maker','');await page.screenshot({path:fileURLToPath(new URL('taxonomy-desktop.png',dir))});
 await page.setViewportSize({width:390,height:844});assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1),false);
 await page.screenshot({path:fileURLToPath(new URL('taxonomy-mobile.png',dir))});assert.deepEqual(errors,[]);
 await writeFile(new URL('taxonomy-validation.json',dir),JSON.stringify({passed:true,asset_count:data.items.length,categories:leaves.length,gaps:gaps.length,local_links_checked:links.filter(l=>l.startsWith('file:')).length,checks:['Unique products and primary categories','Coverage rollup matches exact assets','No fabricated coverage for gaps','Local links resolve','Category, maker and search filters','Four previews decode','Mobile layout fits viewport','No page errors']},null,2)+'\n');
 console.log('Taxonomy and browser checks passed');
}finally{await browser.close()}
