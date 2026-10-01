#!/usr/bin/env python3
"""Import reviewed acquisition JSON, validate images, and stage detailed build records."""
import argparse,csv,hashlib,importlib.util,json,subprocess,sys
from pathlib import Path
from urllib.request import Request,urlopen
from urllib.parse import urlparse
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).parent))
from build_detailed_catalog import fid,dump,CSV,PROFILES,sync_csv
import generate_fixture_assets as base
OFFICIAL=('adj.com','elationlighting.com','chauvetprofessional.com','robe.cz','claypaky.it','glp.de','etcconnect.com','vari-lite.com','harmanpro.com','martin.com','vari-lite.s3.eu-west-1.amazonaws.com','cdn11.bigcommerce.com')
def official(url):return any(urlparse(url).hostname==d or (urlparse(url).hostname or '').endswith('.'+d) for d in OFFICIAL)

def fetch(url,path):
    with urlopen(Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=45) as r:data=r.read()
    path.write_bytes(data)
    result=subprocess.run(['magick','identify',str(path)],capture_output=True,text=True)
    if result.returncode:raise ValueError(f'Not a decodable image: {url}')

def main():
    p=argparse.ArgumentParser();p.add_argument('--batch',type=int,choices=[1,2],required=True);a=p.parse_args()
    rows=list(csv.DictReader(CSV.open()));seen={fid(r) for r in rows};manufacturers={r['manufacturer'] for r in rows};profiles=json.loads(PROFILES.read_text());dimsmap=json.loads(base.MAP.read_text())
    candidates=[r for file in sorted((ROOT/'research/fixtures/expansion').glob('*.json')) for r in json.loads(file.read_text()) if r.get('expansion_batch')==a.batch]
    assert len({fid(r) for r in candidates})==len(candidates),'Duplicate candidate identity'
    assert len(manufacturers|{r['manufacturer'] for r in candidates})<=10,'Manufacturer cap exceeded'
    added=[];failures=[]
    for item in candidates:
        ident=fid(item)
        if ident in seen:continue
        dim=item['dimensions'];assert all(isinstance(dim[k],(float,int)) and dim[k]>0 for k in ('width_m','height_m','depth_m')),ident
        assert item['images'] and item['data'].get('protocols'),ident
        data={k:v for k,v in item['data'].items() if v is not None}
        data['dimensions']=dim;data['research_evidence']=item['evidence']
        row={k:item[k] for k in ('name','model_number','manufacturer','type','subtype','url')};row.update(data=json.dumps(data,ensure_ascii=False),images=json.dumps(item['images']),expansion_batch=a.batch)
        folder=ROOT/'assets/fixtures'/ident;folder.mkdir(parents=True,exist_ok=True)
        _,record=base.record_for(row,dim,folder,False)
        # All research URLs retain their precise locator and primary/secondary classification.
        for ev in item['evidence']:
            found=next((s for s in record['sources'] if s['url']==ev['url']),None)
            if found:found['locator']=ev.get('locator','');found['title']=ev['title']
            else:
                found={'id':f'evidence-{len(record["sources"])+1}','url':ev['url'],'title':ev['title'],'accessed_at':ev.get('accessed_at','2026-09-30'),'document_revision':None,'locator':ev.get('locator',''),'reuse_status':'reference_only'};record['sources'].append(found)
            found['kind']='manufacturer_manual' if official(ev['url']) and ('pdf' in ev['url'].lower() or 'downloadasset' in ev['url'].lower()) else ('manufacturer_product' if official(ev['url']) else 'secondary')
        dsids=[s['id'] for s in record['sources']]
        for axis in ('width','height','depth'):
            record['dimensions'][axis]['source_ids']=dsids
            record['dimensions'][axis]['note']=dim['axis_note']
        pose=dim.get('reference_pose','Reference pose awaiting drawing review')
        record['dimensions']['source_reference_pose']=pose
        record['dimensions']['reference_pose']='Modeled neutral pose; horizontal optical axis, assembled envelope constrained to recorded dimensions'
        record['model']['reference_pose']=record['dimensions']['reference_pose']
        if 'vertical' in pose.lower() or 'straight up' in pose.lower():
            record['status']='researched'
            record['unresolved'].append('Source describes a vertical-head dimensional pose; modeled horizontal optical-axis pose fits that envelope. Verify pose-specific shape before placement/clearance use.')
        family=item['modeling']['family'];profile=dict(item['modeling'])
        if family=='profile' and 'moving' in item['type'].lower():profile['family']='moving_spot'
        if ident=='adj/jolt-bar-fx2':profile.update(family='strobe',strip=True,cells=28)
        if ident=='elation-professional/vbar-270':profile.update(family='batten',pixel_grid=True,lens_count=270)
        if profile['family']=='par' and item['manufacturer']=='ADJ':profile['floor_yoke']=True
        if ident=='claypaky/volero-wave':profile.update(multi_heads=True,lens_count=8)
        if ident=='claypaky/tambora-flash':profile.update(reflector_cells=4)
        if ident=='glp/impression-x5-ip-maxx':profile['baseless']=True
        # Reference copies stay outside runtime assets. Verify decoding before accepting URL.
        url=item['images'][0];ext=Path(urlparse(url).path).suffix.lower()
        if ext not in ('.jpg','.png','.jpeg','.webp'):ext='.jpg'
        image=folder/'sources'/('product-reference'+ext)
        try:
            if not image.exists():fetch(url,image)
            check=subprocess.run(['magick','identify',str(image)],capture_output=True)
            if check.returncode:raise ValueError('Cached reference is not a decodable image')
        except Exception as e:
            failures.append({'id':ident,'url':url,'error':str(e)});print('Reference failed',ident,str(e),flush=True);continue
        record['sources'].append({'id':'product-reference','url':url,'title':item['name']+' product reference','kind':'manufacturer_asset' if official(url) else 'secondary','accessed_at':'2026-09-30','document_revision':None,'locator':'Reference image; exact-model identity visually reviewed separately','reuse_status':'reference_only' if official(url) else 'unknown','file':image.relative_to(folder).as_posix(),'sha256':hashlib.sha256(image.read_bytes()).hexdigest()})
        record['model']['status']='not_built';record['model']['artifacts']=[]
        record['revision_notes']=['Acquired in expansion batch '+str(a.batch)+'. Technical sources retained with locators; detailed model build pending.']
        dump(folder/'fixture.json',record);base.write_note(folder,row,record)
        rows.append(row);seen.add(ident);profiles[ident]=profile;dimsmap[item['manufacturer']+'|'+item['name']]=dim;added.append(ident)
        # Checkpoint after each accepted image, so network retries never duplicate rows.
        dump(PROFILES,profiles);dump(base.MAP,dimsmap);sync_csv(rows)
        print('Imported',ident,flush=True)
    print('Batch',a.batch,'added',len(added))
    dump(ROOT/f'research/fixtures/import-failures-{a.batch}.json',failures)
    if failures:raise SystemExit(1)
if __name__=='__main__':main()
