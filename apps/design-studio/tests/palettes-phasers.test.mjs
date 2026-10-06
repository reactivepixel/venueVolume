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
