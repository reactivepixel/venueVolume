// Independent spreadsheet-engine import check of the published machine CSVs.
import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import { Workbook } from '@oai/artifact-tool';
const root=new URL('../../',import.meta.url);
const reports=[];
for(const filename of ['major-manufacturer-fixtures.csv','show-equipment-catalog.csv']){
 const text=await fs.readFile(new URL('assets/fixtures/research/'+filename,root),'utf8');
 const workbook=await Workbook.fromCSV(text,{sheetName:'Catalog'});
 const values=workbook.worksheets.getItem('Catalog').getUsedRange().values;
 const fields=values[0];const identities=new Set();
 for(const field of ['name','model_number','manufacturer','type','subtype','url','data','images','pipelineErrors','pipelineStatus'])assert.ok(fields.includes(field),field);
 let records=0;
 for(const cells of values.slice(1)){
  if(!cells.some(v=>v!==''&&v!==null))continue;
  const row=Object.fromEntries(fields.map((field,i)=>[field,cells[i]??'']));
  const id=row.manufacturer+'|'+row.name;assert.ok(!identities.has(id),id);identities.add(id);
  assert.equal(typeof JSON.parse(row.data),'object');
  assert.ok(Array.isArray(JSON.parse(row.images)));assert.ok(/^https?:\/\//.test(row.url));
  if(row.pipelineStatus!=='complete')assert.ok(row.pipelineErrors,id);
  if(row.asset_state==='research_only'){assert.equal(row.usdz_asset,'');assert.equal(row.blend_asset,'');}
  records++;
 }
 reports.push({filename,records,columns:fields.length,passed:true});
 console.log((await workbook.inspect({kind:'table',range:'Catalog!A1:F4',tableMaxRows:4,tableMaxCols:6,maxChars:1000})).ndjson);
}
await fs.writeFile(new URL('assets/fixtures/research/csv-import-validation.json',root),JSON.stringify({passed:true,engine:'Artifact Tool CSV importer',reports},null,2)+'\n');
console.log(JSON.stringify(reports));
