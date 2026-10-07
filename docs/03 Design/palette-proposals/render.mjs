import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const dir=path.dirname(fileURLToPath(import.meta.url));
const require=createRequire(path.resolve(dir,'../../../apps/design-studio/package.json'));
const {chromium}=require('@playwright/test');
const browser=await chromium.launch({headless:true,executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'});
try {
 const page=await browser.newPage({viewport:{width:1480,height:1040},deviceScaleFactor:1.5});
 await page.goto(new URL('./panels.html',import.meta.url).href);
 await page.evaluate(()=>document.fonts.ready);
 for(const [i,id] of ['apple','console','norman','cooper','victor'].entries()) {
   const locator=page.locator('#'+id);
   await locator.screenshot({path:path.join(dir,`${i+1}-${id}.png`)});
   console.log(id,await locator.evaluate(e=>({width:e.clientWidth,height:e.clientHeight,overflow:e.scrollHeight>e.clientHeight})));
 }
} finally {await browser.close();}
