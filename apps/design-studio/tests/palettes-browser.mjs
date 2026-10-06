import { chromium, expect } from '@playwright/test';
import { emptyWorkspace, transition } from '../src/workspace-model.js';
const state=transition(emptyWorkspace(),{type:'add-loadout',id:'palette-review',name:'Palette Review',venueId:'room'},[{id:'room',name:'Room',assetUrl:'/scan.ply',status:'ready',setupStatus:'configured'}]);
const browser=await chromium.launch({headless:true,executablePath:process.env.VV_CHROMIUM_EXECUTABLE || '/usr/bin/chromium'});
try {
 const page=await browser.newPage({viewport:{width:1440,height:1080}});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.addInitScript(s=>localStorage.setItem('vv-workspace-v2',JSON.stringify(s)),state);
 const base=process.env.VV_BASE_URL || 'http://127.0.0.1:5173';
 await page.goto(`${base}/?screen=preset-editor&loadoutId=palette-review`);
 await expect(page.getByText('Palette & phaser workbench',{exact:true})).toBeVisible();
 await page.getByRole('combobox',{name:'Palette library'}).selectOption({label:'Phaser · Dimmer chase'});
 await page.getByRole('button',{name:'Duplicate and customize'}).click();
 await page.getByLabel('Palette name').fill('Custom chase');
 await page.getByRole('button',{name:'Add step',exact:true}).click();
 await page.getByRole('button',{name:'Save palette / phaser',exact:true}).click();
 await expect(page.getByText('Saved palette and phaser values.',{exact:true})).toBeVisible();
 await page.reload();
 await page.getByRole('combobox',{name:'Palette library'}).selectOption({label:'Custom chase'});
 await expect(page.getByText('Step 3',{exact:true})).toBeVisible();
 await page.getByRole('combobox',{name:'Palette library'}).selectOption({label:'Phaser · Dimmer chase'});
 await expect(page.getByText('Step 3',{exact:true})).toHaveCount(0);
 if(errors.length) throw new Error(errors.join('\n'));
 console.log('PASS independent duplicate, editing, save and persisted three-step phaser');
} finally { await browser.close(); }
