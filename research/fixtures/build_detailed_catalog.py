#!/usr/bin/env python3
"""Candidate-first detailed builds; preserve records, evidence, and manual edits."""
import argparse,copy,csv,hashlib,importlib.util,json,os,re,shutil,subprocess,sys,tempfile
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor,as_completed
ROOT=Path(__file__).resolve().parents[2]
BUILDER=ROOT/'assets/fixtures/_shared/detailed_fixture.py'
CSV=ROOT/'assets/fixtures/research/major-manufacturer-fixtures.csv'
LIB=ROOT/'docs/08 Fixture Library/skill/create-venue-fixture/scripts/library.py'
CHECK=LIB.with_name('check_usdz.py')
PROFILES=ROOT/'research/fixtures/detail_profiles.json'
DATE='2026-09-30'

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,obj):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(obj,indent=2,ensure_ascii=False)+'\n')
def fid(row):return '/'.join(re.sub('[^a-z0-9]+','-',row[k].lower()).strip('-') for k in ('manufacturer','name'))
def artifact(folder,role,file):return {'role':role,'file':file,'sha256':sha(folder/file)}

def wrapper(spec,builder=BUILDER):
    return f'''#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/{builder.name}").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={spec!r}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
'''

def run(cmd,log,env=None):
    r=subprocess.run(cmd,capture_output=True,text=True,env=env,timeout=180)
    log.write_text(log.read_text()+'\n'+r.stdout+r.stderr if log.exists() else r.stdout+r.stderr)
    if r.returncode:raise RuntimeError(f'{cmd[0]} failed ({r.returncode}); see {log}')

def build_one(row,profile,force=False):
    ident=fid(row);folder=ROOT/'assets/fixtures'/ident;rp=folder/'fixture.json';record=json.loads(rp.read_text())
    builder=BUILDER.with_name('equipment_fixture.py') if profile.get('generator')=='equipment' else BUILDER
    dependency_hash=sha(BUILDER)+(sha(builder) if builder!=BUILDER else '')
    token=hashlib.sha256((dependency_hash+json.dumps(profile,sort_keys=True)+json.dumps(record['dimensions'],sort_keys=True)).encode()).hexdigest()
    if record['model'].get('detail_build_token')==token and not force:return ident,'already_current'
    for a in record['model']['artifacts']:
        if sha(folder/a['file'])!=a['sha256']:raise RuntimeError(f'Manual edit preserved; refusing overwrite: {ident}/{a["file"]}')
    spec={'id':ident,**{axis+'_m':record['dimensions'][axis]['value'] for axis in ('width','height','depth')},'profile':profile,'source_urls':[s['url'] for s in record['sources']]}
    log=ROOT/'research/fixtures/build-logs'/Path(ident.replace('/','--')+'.log');log.parent.mkdir(exist_ok=True)
    old_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
    with tempfile.TemporaryDirectory(prefix='vv-detail-') as tmp:
        candidate=Path(tmp);(candidate/'models').mkdir();(candidate/'validation').mkdir()
        driver=candidate/'build.py'
        driver.write_text(f"import importlib.util,os,sys,traceback\nfrom pathlib import Path\ntry:\n s=importlib.util.spec_from_file_location('detail',{str(builder)!r})\n m=importlib.util.module_from_spec(s);s.loader.exec_module(m)\n m.build({spec!r},Path({str(candidate)!r}))\nexcept BaseException:\n traceback.print_exc();sys.stdout.flush();sys.stderr.flush();os._exit(1)\nsys.stdout.flush();sys.stderr.flush();os._exit(0)\n")
        run(['blender','--background','--threads','2','--python-exit-code','1','--python',str(driver)],log)
        detail=json.loads((candidate/'validation/detail.json').read_text())
        # Rebuilding an unpublished candidate is the same library revision.
        published=subprocess.run(['git','show','HEAD:'+rp.relative_to(ROOT).as_posix()],cwd=ROOT,capture_output=True,text=True)
        published_record=json.loads(published.stdout) if published.returncode==0 else {}
        is_published=published_record.get('revision')==record['revision'] and published_record.get('model',{}).get('detail_build_token')==record['model'].get('detail_build_token')
        prior_is_batch=record['model'].get('detail_batch')=='catalog-expansion-2026-09-30' and not is_published
        new=copy.deepcopy(record)
        if not prior_is_batch:new['revision']+=1
        new['updated_at']=DATE
        model=new['model'];model['parts']=detail['parts'];model['emitters']=[detail['emitter']]
        output_kind=profile.get('output_kind','light')
        if output_kind!='light':
            model['emitters']=[]
            model['effect_outlets']=[] if output_kind=='none' else [{'prim_path':detail['emitter']['prim_path'],'position_m':detail['emitter']['position_m'],'kind':output_kind,'status':'estimated','note':'Visualization anchor only; no simulated emission, operational control, safety envelope or firing parameters.'}]
        model['joints']=[]
        if profile['family'].startswith('moving_'):
            piv={p['name']:p['pivot_m'] for p in detail['parts']}
            model['joints']=[{'name':'pan','parent':'base','child':'yoke','pivot_m':piv['yoke'],'axis':[0,1,0],'status':'estimated','limits':None},{'name':'tilt','parent':'yoke','child':'head','pivot_m':piv['head'],'axis':[1,0,0],'status':'estimated','limits':None}]
        model.update({'detail_level':'high','detail_batch':'catalog-expansion-2026-09-30','detail_build_token':token,'generator_dependency':{'file':'../../_shared/'+builder.name,'sha256':sha(builder)},'profile':profile,'mesh_count':detail['mesh_count'],'triangle_count':detail['triangle_count'],'authoring_to_runtime':detail['authoring_to_runtime']})
        if builder!=BUILDER:model['generator_dependencies']=[{'file':'../../_shared/'+p.name,'sha256':sha(p)} for p in (builder,BUILDER)]
        model['assumptions']=[s for s in model['assumptions'] if 'articulation joints' not in s and 'Moving components remain' not in s]
        model['assumptions']+=['Detailed original procedural geometry; contours, bracket thickness, vent patterns, connectors and pivot positions are image-informed approximations.', 'Blender and USDZ use the same evaluated geometry, materials and part pivots. Pan/tilt metadata has estimated pivots, unknown limits and no authored physics joints.']
        model['assumptions']=list(dict.fromkeys(model['assumptions']))
        new['revision_notes'].append(f"Revision {new['revision']}: detailed {profile['family']} geometry, editable part pivots, full-detail USDZ export and four refreshed previews.")
        dump(candidate/'fixture.json',new)
        run(['blender','--background','--threads','2','--python-exit-code','1','--python',str(CHECK),'--',str(candidate/'fixture.json')],log)
        report=json.loads((candidate/'validation/usdz.json').read_text());assert report['passed']
        # Preserve prior manifest; its binaries and sources remain recoverable from this Git revision.
        if not prior_is_batch:
            archive=folder/f'revisions/revision-{record["revision"]}'
            for art in record['model']['artifacts']:
                dst=archive/art['file'];dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(folder/art['file'],dst)
            dump(folder/f'revisions/revision-{record["revision"]}.json',{'record':record,'git_commit':old_commit,'artifact_directory':archive.relative_to(folder).as_posix(),'note':'Prior artifact bytes preserved in artifact_directory.'})
        for group in ('models','previews','validation'):
            (folder/group).mkdir(parents=True,exist_ok=True)
            for path in (candidate/group).iterdir():shutil.copy2(path,folder/group/path.name)
        (folder/'models/build_fixture.py').write_text(wrapper(spec,builder))
        model['bounds_m']=report['bounds_m'];model['status']='validated'
        if builder!=BUILDER:
            new['status']='ready_for_visualization' if all(new['dimensions'][a]['status']=='documented' for a in ('width','height','depth')) and not new['unresolved'] else 'researched'
            new['verification']['notes']=['OpenUSD structure, dimensional envelope and declared hierarchy checked. Physical source truth, RealityKit rendering and hardware operation require separate review.']
        model['artifacts']=[artifact(folder,role,file) for role,file in [('authoring','models/fixture.blend'),('runtime','models/fixture.usdz'),('generator','models/build_fixture.py'),('validation','validation/usdz.json'),('validation','validation/detail.json')]]
        model['artifacts'] += [artifact(folder,'preview',f'previews/{n}.png') for n in ('front','side','rear','three-quarter')]
        dump(rp,new)
        note=ROOT/'docs/08 Fixture Library/entries'/Path(ident+'.md')
        old_note=note.read_text();section='## Detailed model revision'
        if section in old_note:old_note=old_note.split(section)[0].rstrip()+'\n'
        note.write_text(old_note+f'\n{section}\n\nRevision {new["revision"]} uses a `{profile["family"]}` profile with {detail["mesh_count"]} visible meshes and {detail["triangle_count"]:,} triangles. The editable Blender model and runtime USDZ contain the same evaluated geometry. Local contours, details and joint pivots remain estimated from manufacturer imagery. Existing dimensional evidence and unresolved axis assignments remain unchanged.\n\n[Detail and parity report](../../../../assets/fixtures/{ident}/validation/detail.json) · [Front](../../../../assets/fixtures/{ident}/previews/front.png) · [Side](../../../../assets/fixtures/{ident}/previews/side.png) · [Rear](../../../../assets/fixtures/{ident}/previews/rear.png) · [Three-quarter](../../../../assets/fixtures/{ident}/previews/three-quarter.png)\n')
        run([sys.executable,str(LIB),'validate','--root',str(ROOT),str(rp)],log)
    return ident,'built'

def sync_csv(rows):
    fields=list(dict.fromkeys(k for row in rows for k in row));extra=['model_fidelity','model_revision','preview_asset','detail_report','expansion_batch']
    fields += [f for f in extra if f not in fields]
    for row in rows:
        ident=fid(row);folder=ROOT/'assets/fixtures'/ident;path=folder/'fixture.json'
        if not path.exists():continue
        r=json.loads(path.read_text());row.update({'asset_state':r['status'],'model_fidelity':r['model'].get('detail_level','proxy'),'model_revision':r['revision'],'asset_root':str(folder.relative_to(ROOT)),'fixture_record':str(path.relative_to(ROOT)),'fixture_note':f'docs/08 Fixture Library/entries/{ident}.md','blend_asset':f'assets/fixtures/{ident}/models/fixture.blend','usdz_asset':f'assets/fixtures/{ident}/models/fixture.usdz','validation_report':f'assets/fixtures/{ident}/validation/usdz.json','preview_asset':f'assets/fixtures/{ident}/previews/three-quarter.png','detail_report':f'assets/fixtures/{ident}/validation/detail.json' if r['model'].get('detail_level')=='high' else ''})
    with CSV.open('w',newline='') as f:w=csv.DictWriter(f,fieldnames=fields,lineterminator='\n');w.writeheader();w.writerows(rows)

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--only',action='append');ap.add_argument('--workers',type=int,default=2);ap.add_argument('--force',action='store_true');a=ap.parse_args()
    profiles=json.loads(PROFILES.read_text());rows=list(csv.DictReader(CSV.open()));selected=[r for r in rows if not a.only or fid(r) in a.only]
    failures=[]
    with ThreadPoolExecutor(max_workers=a.workers) as pool:
        jobs={pool.submit(build_one,r,profiles[fid(r)],a.force):fid(r) for r in selected}
        for future in as_completed(jobs):
            try:print(*future.result(),flush=True)
            except Exception as e:failures.append({'id':jobs[future],'error':str(e)});print('FAILED',jobs[future],str(e),flush=True)
    sync_csv(rows)
    dump(ROOT/'research/fixtures/build-failures.json',failures)
    if failures:raise SystemExit(1)
    subprocess.run([sys.executable,str(LIB),'index','--root',str(ROOT)],check=True)
if __name__=='__main__':main()
