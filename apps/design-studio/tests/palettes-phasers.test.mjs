import test from 'node:test';
import assert from 'node:assert/strict';
import { baselinePalettes, samplePhaser } from '../src/palettes-phasers.js';
test('baseline chase distributes phases and snaps intensity', () => {
 const p = baselinePalettes.find(p => p.name.includes('chase'));
 assert.equal(samplePhaser(p, 0).intensity, 100);
 assert.equal(samplePhaser(p, 0.5).intensity, 0);
 assert.equal(samplePhaser(p, 0, 1, 2).intensity, 0);
 assert.equal(samplePhaser(p, 1).intensity, 100);
});
test('duplicate steps remain independent and measure slows cycle', () => {
 const p = structuredClone(baselinePalettes.find(p => p.name.includes('Breathe')));
 const clone = structuredClone(p); clone.phaser.steps[0].intensity = 0;
 assert.equal(p.phaser.steps[0].intensity, 10);
 p.phaser.measure = 2;
 assert.equal(samplePhaser(p, 1).intensity, 55);
});

test('malformed imported phasers fall back to static palette safely', () => {
 for (const phaser of [{}, {steps:[]}, {steps:[{},{}],bpm:60,measure:0}, {steps:[{width:Infinity},{}],bpm:60,measure:1}]) {
  assert.deepEqual(samplePhaser({intensity:25,color:'#ffffff',phaser},1),{intensity:25,color:'#ffffff',pan:0,tilt:0});
 }
});
import {cueValues, outputValue} from '../src/live-model.js';
test('static position and color coexist with intensity chase in cue output', () => {
 const intensity=baselinePalettes.find(p=>p.name.includes('chase'));
 const color=baselinePalettes.find(p=>p.name==='Color · Red');
 const position={...baselinePalettes.find(p=>p.type==='Position'),pan:45,tilt:30};
 const fixture={id:'one',role:'Wash'};
 const entry={entryId:'cue',assignments:[{role:'Wash',paletteNames:[intensity.name,color.name,position.name]}]};
 const snapshot={fixtures:[fixture],presets:[intensity,color,position],script:[entry]};
 const values=cueValues(snapshot,entry);
 assert.equal(values.one.color,'#ff0000');
 assert.equal(values.one.pan,50+45/270*100);
 assert.equal(values.one.tilt,75);
 const run={snapshot,activeId:'cue',activeValues:values,programmer:{},armed:true,master:100,groupMasters:{},connected:true};
 assert.equal(outputValue(run,fixture,0.5).intensity,0);
 assert.equal(outputValue(run,fixture,0.5).color,'#ff0000');
 run.programmer.one={intensity:75};
 assert.equal(outputValue(run,fixture,0.5).effective,75);
});

import {applyPaletteToCue, createPalette, paletteIssue, renamePaletteReferences} from '../src/palettes-phasers.js';
import {assignmentPalettes} from '../src/live-model.js';
test('step palette sources stay linked and survive palette rename', () => {
 const red = {...createPalette('Color'), name:'Source red', color:'#ff0000'};
 const blue = {...createPalette('Color'), name:'Source blue', color:'#0000ff'};
 const chase = {...createPalette('Color'), name:'Linked color', phaser:{bpm:60,measure:1,transition:0,steps:[{paletteName:red.name},{paletteName:blue.name}]}};
 assert.equal(paletteIssue(chase,[red,blue]),null);
 assert.equal(samplePhaser(chase,0,0,1,[red,blue]).color,'#ff0000');
 red.color='#00ff00';
 assert.equal(samplePhaser(chase,0,0,1,[red,blue]).color,'#00ff00');
 const data={presets:[red,blue,chase],script:[{entryId:'one',preset:red.name,assignments:[{role:'Wash',preset:red.name,paletteNames:[red.name,chase.name]}]}]};
 const changed=renamePaletteReferences(data,{...red,name:'Source green'},red.name);
 assert.equal(changed.presets[2].phaser.steps[0].paletteName,'Source green');
 assert.equal(changed.script[0].preset,'Source green');
 assert.deepEqual(changed.script[0].assignments[0].paletteNames,['Source green',chase.name]);
 assert.equal(samplePhaser(changed.presets[2],0,0,1,changed.presets).color,'#00ff00');
 assert.ok(paletteIssue({...chase,phaser:{...chase.phaser,steps:[{paletteName:chase.name},{}]}},[chase]));
});
test('fixture application layers above group defaults without changing unselected fixtures', () => {
 const dimmer={...createPalette(),name:'Half',intensity:50};
 const red={...createPalette('Color'),name:'Red',color:'#ff0000'};
 const blue={...createPalette('Color'),name:'Blue',color:'#0000ff'};
 const fixtures=[{id:'one',role:'Wash'},{id:'two',role:'Wash'}];
 const script=[{entryId:'cue',assignments:[{role:'Wash',paletteNames:[dimmer.name,red.name]}]}];
 const applied=applyPaletteToCue(script,'cue',['one'],blue,fixtures,[dimmer,red,blue]);
 const snapshot={fixtures,presets:[dimmer,red,blue],script:applied};
 const values=cueValues(snapshot,applied[0]);
 assert.equal(values.one.intensity,50); assert.equal(values.one.color,'#0000ff');
 assert.equal(values.two.intensity,50); assert.equal(values.two.color,'#ff0000');
 assert.equal(script[0].assignments.length,1);
 assert.equal(assignmentPalettes(snapshot,applied[0],fixtures[0]).at(-1).name,'Blue');
});
test('a later static layer stops the phaser only for overlapping attributes', () => {
 const chase=baselinePalettes.find(p=>p.name.includes('Dimmer chase'));
 const half={...createPalette(),name:'Half',intensity:50};
 const fixture={id:'one',role:'Wash'};
 const entry={entryId:'cue',assignments:[{role:'Wash',paletteNames:[chase.name,half.name]}]};
 const snapshot={fixtures:[fixture],presets:[chase,half],script:[entry]};
 const run={snapshot,activeId:'cue',activeValues:cueValues(snapshot,entry),programmer:{},armed:true,master:100,groupMasters:{},connected:true};
 assert.equal(outputValue(run,fixture,.5).intensity,50);
});

test('transition enters target then holds, with a per-step override',()=>{
 const p={...createPalette(),phaser:{bpm:60,measure:2,transition:1,steps:[{intensity:100,transition:.5},{intensity:0,transition:0}]}};
 assert.equal(samplePhaser(p,0).intensity,0);
 assert.equal(samplePhaser(p,.25).intensity,50);
 assert.equal(samplePhaser(p,.75).intensity,100);
 assert.equal(samplePhaser(p,1).intensity,0);
});
import {planMacro, starterMacros} from '../src/programming-macros.js';
test('macro preflights every row, resolves scope once and remains repeatable',()=>{
 const fixtures=[{id:'a',role:'Wash'},{id:'b',role:'Spot'}],script=[{entryId:'cue'}];
 const args={selection:['a'],fixtures,palettes:baselinePalettes,script,entryId:'cue'};
 const macro=starterMacros[0],plan=planMacro(macro,args);
 assert.deepEqual(plan.ids,['a']);assert.equal(plan.script[0].assignments.length,1);
 assert.equal(plan.script[0].assignments[0].fixtureId,'a');assert.deepEqual(script,[{entryId:'cue'}]);
 assert.deepEqual(planMacro(macro,{...args,script:plan.script}).script,plan.script);
 assert.throws(()=>planMacro(macro,{...args,selection:[]}));
 assert.throws(()=>planMacro({...macro,lines:[...macro.lines,{paletteName:'Missing',enabled:true}]},args));
 assert.deepEqual(planMacro({...macro,lines:[...macro.lines,{paletteName:'Missing',enabled:false}]},args).script,plan.script);
 assert.deepEqual(planMacro({...macro,target:{kind:'role',role:'Spot'}},args).ids,['b']);
 const renamed=renamePaletteReferences({presets:baselinePalettes,script,macros:[macro]}, {...baselinePalettes[0],name:'Full renamed'},baselinePalettes[0].name);
 assert.equal(renamed.macros[0].lines[0].paletteName,'Full renamed');
});
