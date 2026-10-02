#!/usr/bin/env python3
"""Resumable acquisition/build pipeline; no product is dropped for missing evidence.

Input: reviewed expansion-v2/*.json acquisition arrays. Output: research backlog,
new fixture packages and a per-product event ledger. Publication is a separate step.
"""
import argparse
import csv
import hashlib
import json
import math
import re
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.parse import urlparse
import build_detailed_catalog as detail
import generate_fixture_assets as base
from import_show_equipment import EQUIPMENT, OUTLETS, PASSIVE, source_kind

ROOT = Path(__file__).resolve().parents[2]
ACQUISITION = ROOT/'research/fixtures/expansion-v2'
LEDGER = ACQUISITION/'pipeline-ledger.json'
DATE = '2026-10-02'
SUPPORTED = {'moving_spot','moving_wash','batten','strobe','par','profile','fresnel','blinder'} | EQUIPMENT

def candidates():
    found = {}
    for path in sorted(ACQUISITION.glob('*.json')):
        data = json.loads(path.read_text())
        if not isinstance(data, list): continue
        for item in data:
            if not isinstance(item, dict) or not all(k in item for k in ('name','manufacturer','url')): continue
            ident = detail.fid(item)
            if ident in found and found[ident] != item: raise ValueError('Conflicting acquisition identity: '+ident)
            found[ident] = item
    overrides=ACQUISITION/'modeling-overrides.json'
    if overrides.exists():
        for ident,profile in json.loads(overrides.read_text()).items():
            if ident in found:found[ident]['modeling'].update(profile)
    return found

def issues(item):
    errors = []
    d = item.get('dimensions') or {}
    if not all(isinstance(d.get(k), (int,float)) and math.isfinite(d[k]) and d[k] > 0 for k in ('width_m','height_m','depth_m')):
        errors.append('A sourced assembled width, height and depth have not all been established')
    data = item.get('data') or {}
    if not any(re.search(r'dmx|art[ -]?net|sacn', p, re.I) for p in data.get('protocols') or []):
        errors.append('DMX or network lighting control compatibility has not been verified')
    if not item.get('images'): errors.append('An exact-model product reference image is unavailable')
    if not item.get('evidence'): errors.append('Technical source evidence is missing')
    if (item.get('modeling') or {}).get('family') not in SUPPORTED:
        errors.append('The model needs a supported geometry profile')
    profile=item.get('modeling') or {}
    if 'lens_count' in profile and profile['lens_count'] is None:
        errors.append('The visible optical module count has not been established')
    if item.get('acquisition_errors'):
        values=item['acquisition_errors']
        errors.extend(str(v).rstrip('.') for v in (values if isinstance(values,list) else [values]))
    return errors

def as_row(item):
    data = {k:v for k,v in (item.get('data') or {}).items() if v is not None}
    data.update(dimensions=item.get('dimensions'), research_evidence=item.get('evidence', []))
    return {k:item.get(k,'') for k in ('name','model_number','manufacturer','type','subtype','url')} | {
        'data':json.dumps(data, ensure_ascii=False), 'images':json.dumps(item.get('images') or []),
        'expansion_batch':'touring-dj-2026-10', 'pipelineErrors':''}

def get_reference(item, folder):
    errors = []
    previous = {}
    record_path = folder/'fixture.json'
    if record_path.exists():
        previous = {s.get('file'):s for s in json.loads(record_path.read_text()).get('sources',[]) if s.get('file')}
    for i, url in enumerate(item['images']):
        ext = Path(urlparse(url).path).suffix.lower()
        if ext not in ('.png','.jpg','.jpeg','.webp','.svg'): ext = '.png'
        path = folder/'sources'/f'product-reference-{i}{ext}'
        path.parent.mkdir(parents=True, exist_ok=True)
        try:
            source = previous.get(path.relative_to(folder).as_posix(),{})
            if path.exists() and source.get('sha256') and detail.sha(path) != source['sha256']:
                raise ValueError('Manual reference-image edit preserved: '+str(path.relative_to(ROOT)))
            if not path.exists() or source.get('url') != url:
                with urlopen(Request(url, headers={'User-Agent':'Mozilla/5.0'}), timeout=30) as response:
                    payload = response.read(25_000_001)
                if len(payload) > 25_000_000: raise ValueError('Reference image exceeds 25 MB')
                path.write_bytes(payload)
            result = subprocess.run(['magick','identify',str(path)], capture_output=True, text=True)
            if result.returncode: raise ValueError('Downloaded reference is not a decodable image')
            return url, path
        except Exception as error: errors.append(str(error))
    raise ValueError('No reference image could be acquired: '+'; '.join(dict.fromkeys(errors)))

def prepare(item, refresh=False):
    ident = detail.fid(item); folder = ROOT/'assets/fixtures'/ident
    errors = issues(item)
    if errors: return None, {'stage':'research','status':'blocked','errors':errors}
    existing=None
    if (folder/'fixture.json').exists():
        existing = json.loads((folder/'fixture.json').read_text())
        if not refresh:
            if existing['model']['status'] == 'validated': return as_row(item), {'stage':'model','status':'already_built','errors':[]}
            return as_row(item), {'stage':'model','status':'ready','errors':[]}
        for artifact in existing['model']['artifacts']:
            if detail.sha(folder/artifact['file']) != artifact['sha256']:
                raise ValueError('Manual artifact edit preserved: '+artifact['file'])
    row = as_row(item)
    try: url, image = get_reference(item, folder)
    except Exception as error: return None, {'stage':'reference','status':'blocked','errors':[str(error)]}
    dims = dict(item['dimensions'])
    dims.setdefault('axis_status','estimated')
    dims.setdefault('axis_note','Dimensions are sourced; neutral-pose axis assignment is estimated from the product image.')
    if dims['axis_status'] not in ('documented','measured','estimated'): dims['axis_status']='estimated'
    dims.setdefault('reference_pose','Manufacturer assembled envelope; optical forward pose is a visualization estimate.')
    base.TODAY = DATE
    _, record = base.record_for(row, dims, folder, False)
    record['status'] = 'researched'
    record['model'].update(status='not_built', artifacts=[], parts=[], joints=[], emitters=[])
    record['dimensions']['reference_pose'] = dims['reference_pose']
    record['model']['reference_pose'] = dims['reference_pose']
    record['verification']['notes'] = ['Asset build and native validation pending.']
    record['sources'] = []
    for i, evidence in enumerate(item['evidence'], 1):
        record['sources'].append(dict(id=f'official-{i}',url=evidence['url'],title=evidence.get('title',item['name']),
             kind={'manufacturer_product_image':'manufacturer_asset','manufacturer_article':'manufacturer_product'}.get(source_kind(evidence),source_kind(evidence)),accessed_at=evidence.get('accessed_at',DATE),document_revision=evidence.get('document_revision'),
             locator=evidence.get('locator','Product specifications'),reuse_status='reference_only'))
    ids = [s['id'] for s in record['sources']]
    for axis in ('width','height','depth'):
        record['dimensions'][axis]['source_ids'] = ids
        record['dimensions'][axis]['note'] = dims['axis_note']
    for group in record['features'].values():
        for fact in group.values(): fact['source_ids'] = ids
    for mode in record['dmx_modes']: mode['source_ids'] = ids
    raw_modes = (item.get('data') or {}).get('dmx_channels')
    if isinstance(raw_modes, dict):
        record['dmx_modes'] = [dict(name=name,footprint=count,source_ids=ids,mapping_status='not_transcribed',channels=[])
                               for name,count in raw_modes.items() if isinstance(count,int) and 1 <= count <= 512]
    record['sources'].append(dict(id='product-reference',url=url,title=item['name']+' product reference',kind='manufacturer_asset',
        accessed_at=DATE,document_revision=None,locator='Exact-model reference image',reuse_status='reference_only',
        file=image.relative_to(folder).as_posix(),sha256=detail.sha(image)))
    record['revision_notes'] = ['Source-backed acquisition for expanded touring, mid-market and DJ catalog.']
    if existing:
        record['model']=existing['model'];record['revision']=existing['revision']
        record['revision_notes']=existing['revision_notes']
    record['acquisition_sha256']=hashlib.sha256(json.dumps(item,sort_keys=True).encode()).hexdigest()
    detail.dump(folder/'fixture.json', record)
    base.write_note(folder, row, record)
    return row, {'stage':'model','status':'ready','errors':[]}

def main():
    parser=argparse.ArgumentParser(); parser.add_argument('--workers',type=int,default=4)
    parser.add_argument('--only',action='append'); parser.add_argument('--prepare-only',action='store_true')
    parser.add_argument('--refresh',action='store_true',help='Refresh reviewed research for this expansion batch only; preserve checked model artifacts')
    args=parser.parse_args(); items=candidates(); ACQUISITION.mkdir(exist_ok=True)
    ledger=json.loads(LEDGER.read_text()) if LEDGER.exists() else {}
    profiles=json.loads(detail.PROFILES.read_text()); dimsmap=json.loads(base.MAP.read_text())
    rows=list(csv.DictReader(detail.CSV.open())); byid={detail.fid(r):r for r in rows}
    existing=set(byid); tasks=[]
    for ident,item in items.items():
        if args.only and ident not in args.only: continue
        refresh=args.refresh and byid.get(ident,{}).get('expansion_batch')=='touring-dj-2026-10'
        if ident in existing and not refresh:
            ledger.setdefault(ident,dict(stage='model',status='existing',errors=[])); continue
        try: row,event=prepare(item,refresh=refresh)
        except Exception as error:row,event=None,dict(stage='record',status='failed',errors=[str(error)])
        ledger[ident]=event
        detail.dump(LEDGER,ledger)
        if row:
            profile=dict(item['modeling'])
            if profile['family'] in EQUIPMENT:
                profile['generator']='equipment'; profile.setdefault('output_kind',OUTLETS.get(profile['family'],'none' if profile['family'] in PASSIVE else 'light'))
            profiles[ident]=profile; dimsmap[item['manufacturer']+'|'+item['name']]=item['dimensions']
            tasks.append((ident,row,profile))
        else: print('BLOCKED',ident,event['stage'],flush=True)
    detail.dump(detail.PROFILES,profiles); detail.dump(base.MAP,dimsmap)
    if args.prepare_only: return
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures={pool.submit(detail.build_one,row,profile):(ident,row) for ident,row,profile in tasks}
        for future in as_completed(futures):
            ident,row=futures[future]
            try:
                future.result(); byid[ident]=row
                ledger[ident]=dict(stage='model',status='built',errors=[])
                print('BUILT',ident,flush=True)
            except Exception as error:
                ledger[ident]=dict(stage='model',status='failed',errors=[str(error)])
                print('FAILED',ident,str(error),flush=True)
            detail.sync_csv(list(byid.values())); detail.dump(LEDGER,ledger)
    current=[event for ident,event in ledger.items() if ident in items]
    print(json.dumps({state:sum(v['status']==state for v in current) for state in sorted({v['status'] for v in current})}))

if __name__ == '__main__': main()
