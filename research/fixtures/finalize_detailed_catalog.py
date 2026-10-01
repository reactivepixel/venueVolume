#!/usr/bin/env python3
"""Publish a local review gallery and audit the canonical catalog manifest."""
import csv,hashlib,html,json,re,subprocess,sys
from collections import Counter
from pathlib import Path
from build_detailed_catalog import ROOT,CSV,dump,fid,LIB
rows=list(csv.DictReader(CSV.open()));cards=[];states=Counter();batches=Counter();totalbytes=0
for row in rows:
    ident=fid(row);folder=ROOT/row['asset_root'];rp=folder/'fixture.json';r=json.loads(rp.read_text());model=r['model']
    assert model['detail_level']=='high' and model['status']=='validated',ident
    parity=json.loads((folder/'validation/parity.json').read_text());assert parity['passed'],ident
    data=json.loads(row['data']);raw_modes=data.get('dmx_channels',{})
    if isinstance(raw_modes,dict) and raw_modes and all(type(v)==int and 1<=v<=512 for v in raw_modes.values()):
        r['dmx_modes']=[{'name':str(name),'footprint':count,'source_ids':['official-1'],'mapping_status':'not_transcribed','channels':[]} for name,count in raw_modes.items()]
    row['model_state']=model['status'];row['parity_report']=str((folder/'validation/parity.json').relative_to(ROOT))
    for key in ('images','data'):json.loads(row[key])
    for key in ('fixture_record','fixture_note','blend_asset','usdz_asset','validation_report','preview_asset','detail_report','parity_report'):assert (ROOT/row[key]).is_file(),(ident,key)
    for a in model['artifacts']:
        path=folder/a['file'];assert hashlib.sha256(path.read_bytes()).hexdigest()==a['sha256'],str(path)
    assert hashlib.sha256((folder/model['generator_dependency']['file']).read_bytes()).hexdigest()==model['generator_dependency']['sha256']
    r['revision_notes']=list(dict.fromkeys(r['revision_notes']));dump(rp,r)
    dims=r['dimensions'];note=ROOT/row['fixture_note'];body=note.read_text()
    envelope=' × '.join(f'{dims[k]["value"]:.4f} m {label}' for k,label in [('width','W'),('height','H'),('depth','D')])
    body=re.sub(r'^- Reference envelope:.*$', '- Reference envelope: '+envelope,body,flags=re.M)
    body=re.sub(r'^- Model:.*$', '- Model: high-detail image-informed procedural approximation; editable Blender and full-detail meter-scale USDZ, Y-up and -Z forward. See the current revision below.',body,flags=re.M)
    body=body.replace('Procedural visualization proxy, not manufacturer CAD.','Detailed procedural visualization model, not manufacturer CAD.')
    body=body.replace('Moving components are separated but no runtime articulation joints are authored.','Moving parts have editable pivots; runtime physics joints are not authored.')
    if '## Independent saved-file audit' in body:body=body.split('## Independent saved-file audit')[0].rstrip()+'\n'
    body+=f'\n## Independent saved-file audit\n\n[Blender / USDZ parity](../../../../assets/fixtures/{ident}/validation/parity.json): all saved mesh vertices, triangle topology and material colors match within 1 micrometre. Runtime device rendering, real fixture response, internal mechanisms and clearance certification are not tested.\n'
    note.write_text(body)
    readme=folder/'sources/README.md'
    if readme.exists() and 'No official product-image' in readme.read_text():readme.write_text('# Local reference assets\n\nManufacturer imagery and documents here are research references, not runtime textures. URLs, file hashes, source identity caveats and reuse status are recorded in `../fixture.json`. No redistribution license is implied.\n')
    for archive in (folder/'revisions').glob('revision-*.json'):
        a=json.loads(archive.read_text())
        if not a['record']['model']['artifacts']:
            a.pop('artifact_directory',None);a['note']='Initial research record before any generated model artifacts existed.';dump(archive,a)
            continue
        if a.get('artifact_directory') or not a.get('git_commit'):continue
        old=a['record'];runtime=next((v for v in old['model']['artifacts'] if v['role']=='runtime'),None)
        if runtime:
            check=subprocess.run(['git','show',a['git_commit']+':'+str(folder.relative_to(ROOT)/runtime['file'])],cwd=ROOT,capture_output=True)
            if check.returncode or hashlib.sha256(check.stdout).hexdigest()!=runtime['sha256']:
                a['note']='Intermediate unpublished model revision: manifest retained, binary bytes were superseded and were not archived. git_commit identifies the baseline, not these artifact bytes.';dump(archive,a)
    states[r['status']]+=1;batches[str(row.get('expansion_batch') or 'original')]+=1
    totalbytes+=(folder/'models/fixture.usdz').stat().st_size
    cards.append({'id':ident,'name':row['name'],'manufacturer':row['manufacturer'],'type':row['type']+' / '+row['subtype'],'state':r['status'],'batch':str(row.get('expansion_batch') or 'original'),'dimensions':envelope,'meshes':model['mesh_count'],'triangles':model['triangle_count'],'url':row['url'],'note':'../../../'+row['fixture_note'],'uncertain':any(dims[k]['status']!='documented' for k in ('width','height','depth')) or bool(r['unresolved'])})
assert len({fid(row) for row in rows})==len(rows)
assert len({row['manufacturer'] for row in rows})<=10
with CSV.open('w',newline='') as f:w=csv.DictWriter(f,fieldnames=list(rows[0]),lineterminator='\n');w.writeheader();w.writerows(rows)
summary={'fixture_count':len(rows),'manufacturer_count':len({r['manufacturer'] for r in rows}),'all_models_high_detail':True,'all_runtime_models_validated':True,'all_saved_geometry_parity_checks_passed':True,'asset_states':dict(states),'batches':dict(batches),'runtime_asset_bytes':totalbytes,'representation':'Image-informed procedural approximations, not manufacturer CAD','realitykit_device_test':'not_run','hardware_test':'not_run'}
dump(ROOT/'assets/fixtures/research/catalog-validation.json',summary)
payload=json.dumps(cards,ensure_ascii=False).replace('</','<\\/')
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Venue Volume · Fixture catalog</title>
<style>:root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#10151b;color:#e9eef3;font:15px/1.5 system-ui,sans-serif}header,main{max-width:1500px;margin:auto;padding:28px}h1{margin:0;font-size:32px}p{color:#acbdcd;max-width:1050px}a{color:#91d6f0}nav,form{display:flex;gap:16px;flex-wrap:wrap;margin:18px 0}input,select{background:#1f2a36;color:inherit;border:1px solid #506070;border-radius:6px;padding:10px}label{display:flex;gap:8px;align-items:center}#grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(290px,1fr));gap:20px}article{background:#1b242e;border:1px solid #33404d;border-radius:12px;overflow:hidden}img{width:100%;display:block;aspect-ratio:1;background:#343b42}section{padding:18px}h2{margin:2px 0;font-size:21px}.meta{color:#a5bdce;font-size:13px}.flag{color:#f2cf88}.links{display:flex;flex-wrap:wrap;gap:12px;font-size:13px}article p{margin:8px 0}output{display:block;margin-bottom:20px}small{font-size:12px}</style>
<header><small>VENUE VOLUME / ASSET LIBRARY / 2026-09-30</small><h1>High-detail fixture catalog</h1><p>77 fixtures · 10 manufacturers · 53 upgraded + 24 additions in two batches. Each card links to the editable Blender model, full-detail USDZ, evidence record and independent geometry checks. These are original image-informed approximations—not manufacturer CAD or certified clearance models. Source dimensions, poses and unresolved evidence remain visible in each record. RealityKit device and fixture-hardware tests have not been run.</p>
<nav><a href="major-manufacturer-fixtures.csv">Download CSV</a><a href="catalog-validation.json">Catalog validation</a><a href="geometry-audit.json">Saved-file geometry audit</a><a href="../catalog.json">Library index</a></nav>
<form onsubmit="return false"><label>Search <input id="search" type="search" placeholder="Model, type or manufacturer"></label><label>Manufacturer <select id="maker"><option value="">All</option></select></label><label>Batch <select id="batch"><option value="">All</option><option value="original">Original 53</option><option value="1">Expansion 1</option><option value="2">Expansion 2</option></select></label><label>View <select id="view"><option>three-quarter</option><option>front</option><option>side</option><option>rear</option></select></label></form></header><main><output id="count"></output><div id="grid"></div></main>
<script>const rows=PAYLOAD;const $=id=>document.getElementById(id);const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));for(const m of [...new Set(rows.map(r=>r.manufacturer))].sort())$('maker').add(new Option(m,m));function render(){const q=$('search').value.toLowerCase();const selected=rows.filter(r=>(!$('maker').value||r.manufacturer===$('maker').value)&&(!$('batch').value||r.batch===$('batch').value)&&JSON.stringify([r.name,r.manufacturer,r.type]).toLowerCase().includes(q));$('count').textContent=selected.length+' fixtures';$('grid').innerHTML=selected.map(r=>{const b='../'+r.id+'/';return `<article><a href="${b}previews/${$('view').value}.png"><img loading="lazy" alt="${esc(r.manufacturer+' '+r.name+' '+$('view').value)}" src="${b}previews/${$('view').value}.png"></a><section><div class="meta">${esc(r.manufacturer)} · ${r.batch==='original'?'Original catalog':'Expansion '+r.batch}</div><h2>${esc(r.name)}</h2><p>${esc(r.type)}</p><div class="meta">${esc(r.dimensions)}<br>${r.meshes} meshes · ${r.triangles.toLocaleString()} triangles</div><p class="${r.uncertain?'flag':'meta'}">${r.uncertain?'Evidence / pose caveats — see record':'Documented dimensional envelope'} · ${esc(r.state)}</p><div class="links"><a href="${b}models/fixture.blend">Blender</a><a href="${b}models/fixture.usdz">USDZ</a><a href="${b}fixture.json">Record</a><a href="${esc(r.note)}">Note</a><a href="${b}validation/usdz.json">USDZ check</a><a href="${b}validation/parity.json">Parity</a><a href="${esc(r.url)}">Official source</a></div></section></article>`}).join('')}for(const id of ['search','maker','batch','view'])$(id).addEventListener('input',render);render();</script></html>'''
headline=f"{len(rows)} fixtures · {summary['manufacturer_count']} manufacturers · {batches['original']} upgraded + {len(rows)-batches['original']} additions in {len(batches)-1} batches."
page=page.replace('77 fixtures · 10 manufacturers · 53 upgraded + 24 additions in two batches.',headline).replace('Original 53',f"Original {batches['original']}")
(ROOT/'assets/fixtures/research/catalog-preview.html').write_text(page.replace('PAYLOAD',payload))
subprocess.run([sys.executable,str(LIB),'index','--root',str(ROOT)],check=True)
print(json.dumps(summary,indent=2))
