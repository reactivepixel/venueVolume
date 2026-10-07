import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const dir=path.dirname(fileURLToPath(import.meta.url));
const require=createRequire(path.resolve(dir,'../../../apps/design-studio/package.json'));
const {chromium,expect}=require('@playwright/test');
const browser=await chromium.launch({headless:true,executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',args:['--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
try {
 const page=await browser.newPage({viewport:{width:1630,height:1090},deviceScaleFactor:1.5});
 page.setDefaultTimeout(10000);
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 for(const [i,name] of [[6,'orbit-workspace'],[7,'glass-studio'],[8,'rhythm-desk'],[9,'preview-first'],[10,'tempo-canvas']]){
  await page.goto(new URL(`./panels.html?concept=${i}`,import.meta.url).href);
  await page.waitForFunction(()=>window.panelReady&&window.shaderReady);
  await page.evaluate(()=>document.fonts.ready);
  await page.evaluate(()=>window.freezePanel(.16));
  await page.locator('#proposal').screenshot({path:path.join(dir,`${i}-${name}.png`)});
  const layout=await page.locator('.body').evaluate(body=>{
   const foot=document.querySelector('.footer').getBoundingClientRect();
   return [...body.querySelectorAll('button,.source-field,.step-bottom,.section-title')].filter(e=>e.getBoundingClientRect().height>0&&e.getBoundingClientRect().bottom>foot.top+1).map(e=>({text:e.textContent.trim().slice(0,50),bottom:e.getBoundingClientRect().bottom,footer:foot.top}));
  });console.log(i,JSON.stringify(layout));if(layout.length)throw Error("Clipped controls in proposal "+i);
  await page.getByRole('button',{name:'Configure step 6',exact:true}).click();
  await expect(page.locator('.step-inspector h2')).toHaveText('Step 6');
  await page.getByRole('button',{name:'4 bars',exact:true}).click();
  await expect(page.locator('.step-dot')).toHaveCount(16);
  await page.locator('input[type=range]').fill('12');
  await expect(page.locator('.step-dot')).toHaveCount(12);
  await page.getByRole('button',{name:'Close step settings'}).click();
  await expect(page.locator('.step-inspector')).toBeHidden();
  await page.getByRole('button',{name:'Configure step 2',exact:true}).click();
  await expect(page.locator('.step-inspector')).toBeVisible();
  await page.getByRole('button',{name:'Fade down',exact:true}).click();
  await expect(page.locator('.status')).toContainText('loaded into step 2');
  await page.getByRole('button',{name:'Pulse',exact:true}).last().click();
  if((await page.evaluate(()=>window.panelState())).pattern!=='Pulse')throw Error('pattern failed');
  await page.getByRole('button',{name:'Tap tempo'}).dispatchEvent('click');
  await page.waitForTimeout(600);
  await page.getByRole('button',{name:'Tap tempo'}).dispatchEvent('click');
  const bpm=await page.evaluate(()=>window.panelState().bpm);
  if(bpm<75||bpm>105)throw Error('tap tempo failed '+bpm);
 }
 if(errors.length)throw Error(errors.join('\n'));
 console.log('PASS five renders; WebGL thumbnails, step selection, expansion, count slider, bar shortcuts, step presets, patterns and tap tempo.');
}finally{await browser.close()}
