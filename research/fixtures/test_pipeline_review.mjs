import { chromium } from '../../apps/design-studio/node_modules/@playwright/test/index.mjs';
import assert from 'node:assert/strict';
import { access,readFile,writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
const root=new URL('../../assets/fixtures/research/',import.meta.url);
const report=JSON.parse(await readFile(new URL('pipeline-status.json',root),'utf8'));
const browser=await chromium.launch({headless:true,executablePath:process.env.VV_CHROMIUM_PATH||'/usr/bin/chromium',args:['--no-sandbox']});
const page=await browser.newPage({viewport:{width:1440,height:1000}});const errors=[];
page.on('pageerror',e=>errors.push(e.message));
try{
 await page.goto(new URL('pipeline-review.html',root).href);
 assert.equal(await page.locator('article').count(),report.rows);
 const links=await page.locator('a').evaluateAll(items=>items.map(a=>a.href));
 for(const link of links)if(link.startsWith('file:'))await access(fileURLToPath(link));
 await page.selectOption('#state','blocked');assert.equal(await page.locator('article').count(),report.statuses.blocked||0);
 assert.equal(await page.locator('article img').count(),0);
 await page.selectOption('#state','visual_review_pending');assert.equal(await page.locator('article').count(),report.statuses.visual_review_pending||0);
 await page.selectOption('#state','native_validation_pending');assert.equal(await page.locator('article').count(),report.statuses.native_validation_pending||0);
 await page.fill('#search','Color Force 3 72');assert.equal(await page.locator('article').count(),1);
 await page.locator('article img').evaluate(img=>img.decode());
 await page.fill('#search','');await page.selectOption('#state','');
 await page.screenshot({path:fileURLToPath(new URL('pipeline-review-desktop.png',root))});
 await page.setViewportSize({width:390,height:844});
 assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1),false);
 await page.screenshot({path:fileURLToPath(new URL('pipeline-review-mobile.png',root))});
 assert.deepEqual(errors,[]);
 await writeFile(new URL('pipeline-review-validation.json',root),JSON.stringify({passed:true,rows:report.rows,local_links:links.filter(l=>l.startsWith('file:')).length,checks:['all catalog items rendered','blocked rows have no fabricated asset links','every local link resolves','state and search filters','preview decodes','no mobile overflow','no JavaScript errors']},null,2)+'\n');
 console.log('PASS: complete pipeline review');
}finally{await browser.close()}
