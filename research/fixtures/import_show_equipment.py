#!/usr/bin/env python3
"""Import reviewed category-gap products, preserving unknowns and control paths.

Run only after the acquisition JSON and exact-product reference images are reviewed.
Missing envelopes or reference images stay in the acquisition backlog, not runtime.
"""
import argparse,csv,hashlib,json,shutil,subprocess
from pathlib import Path
from urllib.parse import urlparse
from build_detailed_catalog import ROOT,CSV,PROFILES,fid,dump,sync_csv
from import_expansion import fetch
import generate_fixture_assets as base

ALIASES={'scoop':'flood','dmx_splitter':'splitter','pixel_controller':'pixel_controller','media_processor':'media_server','stage_deck':'deck','projection_screen':'screen','chain_hoist':'hoist','followspot_camera':'tracking_camera'}

EQUIPMENT={'fogger','hazer','low_fog','jet','bubble','snow','co2_jet','spark','flame','fan','confetti','mirror_ball','mirror_motor','tube','pixel_strip','uv','practical','laser','scanner','cyc','followspot','pc','par_can','pinspot','flood','truss','screen','led_panel','scenic_panel','deck','projector','console','node','dimmer','power','media_server','stand','clamp','splitter','pixel_controller','blinder','fluid_container','co2_supply','hoist'}
PASSIVE={'mirror_ball','mirror_motor','truss','screen','scenic_panel','deck','console','node','dimmer','power','media_server','stand','clamp','splitter','pixel_controller','fluid_container','co2_supply','hoist'}
EQUIPMENT.add('pixel_driver');PASSIVE.add('pixel_driver')
EQUIPMENT.update(('power_supply','data_connector','power_connector','tracking_camera','drape'))
PASSIVE.update(('power_supply','data_connector','power_connector','tracking_camera','drape'))
EQUIPMENT.add('safety_hardware');PASSIVE.add('safety_hardware')
OUTLETS={'fogger':'fog','hazer':'haze','low_fog':'low_fog','jet':'fog_jet','bubble':'bubbles','snow':'snow','co2_jet':'co2','spark':'spark','flame':'flame','fan':'air','confetti':'confetti','laser':'laser_aperture','projector':'projection','led_panel':'video_surface'}

def source_kind(ev):
    kind=ev.get('source_kind') or ev.get('kind')
    if kind:
        if kind.startswith('secondary'):return 'secondary'
        return {'manufacturer_specification':'manufacturer_manual','manufacturer_catalogue':'manufacturer_manual','manufacturer_datasheet':'manufacturer_manual'}.get(kind,kind)
    if ev.get('secondary'):return 'secondary'
    return 'manufacturer_manual' if any(k in ev['url'].lower() for k in ('.pdf','downloadasset','/manual')) else 'manufacturer_product'

def read_candidates():
    result=[]
    for file in sorted((ROOT/'research/fixtures/taxonomy').glob('*-candidates.json')):
        data=json.loads(file.read_text());result.extend(data.get('candidates',[]) if isinstance(data,dict) else data)
    return result

def cached_reference(url):
    for manifest in (ROOT/'research/fixtures/taxonomy').glob('*-sources/manifest.json'):
        data=json.loads(manifest.read_text())
        for item in data.get('files',[]):
            if item.get('url')==url and (manifest.parent/item['file']).is_file():return str((manifest.parent/item['file']).relative_to(ROOT))
    return None

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--only',action='append');args=parser.parse_args()
    rows=list(csv.DictReader(CSV.open()));seen={fid(r) for r in rows}
    profiles=json.loads(PROFILES.read_text());dimsmap=json.loads(base.MAP.read_text())
    candidates=read_candidates()
    assert len({fid(r) for r in candidates})==len(candidates),'Duplicate acquisition identities'
    backlog=[];added=[]
    for item in candidates:
        ident=fid(item)
        if args.only and ident not in args.only:continue
        if ident in seen:continue
        dim=dict(item['dimensions']);family=ALIASES.get(item['modeling']['family'],item['modeling']['family'])
        if family=='connector':family='power_connector' if 'powerCON' in item['name'] else 'data_connector'
        if family=='tracking_camera':
            dim['reference_pose']='Head upright, camera optical axis upward to match manufacturer head-vertical height; pan base level.'
        if family=='safety_hardware':
            dim['reference_pose']='Closed quick link with loop plane vertical, long axis horizontal and closure sleeve along the lower edge; no attached rigging. Estimated outer silhouette.'
        if family=='drape':
            dim['reference_pose']='Flattened inventory silhouette at listed finished width and drop; 5 mm illustrative thickness, not installed pleat depth. Ties and hanging rig omitted.'
            dim['axis_note']+=' Render is a flat silhouette only; actual 50%-fullness gathers require production-specific hanging geometry.'
        if family=='power_connector':
            dim['axis_status']='estimated';dim['axis_note']+=' A circular/square conservative envelope is not an exact measured silhouette in both transverse axes.'
        if item['model_number']=='MFX1118':
            dim.update(width_m=.232,height_m=.1245,depth_m=.196,axis_status='estimated')
            dim['reference_pose']='Main appliance resting level with short outlet inside the rear opening and directed upward; external hoses, baseplate and extension nozzle excluded.'
            dim['axis_note']+=' Integration review maps main length to front width using product photos. The rear-facing metal fitting is a gas inlet, not a horizontal output nozzle. Envelope axes/pose are estimated.'
        # Integration review: product-page dimension order is not a neutral-pose
        # drawing. Keep inferred axis/variant decisions visible downstream.
        if family in ('scanner','blinder') and item['name'] in ('Dynasty Scan DMX','STRIKE 4'):
            dim['axis_status']='estimated';dim['axis_note']+=' Neutral-pose axis assignment is image-inferred, not established by a labelled drawing.'
        if item['name']=='M-2020 Mirror Ball':
            dim['reference_pose']='Sphere-only variant; undimensioned suspension loop and chain excluded.'
            dim['axis_note']+=' Only the 508 mm sphere is modeled; hanging hardware is omitted.'
        if item['name']=='PIXEL DRIVER 170':
            dim.update(height_m=.05,depth_m=.0262,axis_status='estimated')
            dim['axis_note']+=' Display-forward axes rotated from the manufacturer L/W/H list using the photo; 50 mm is face height and 26.2 mm enclosure depth. Mounting tabs excluded.'
        if dim['axis_status'].startswith('estimated'):dim['axis_status']='estimated'
        if not all(type(dim.get(k)) in (float,int) and dim[k]>0 for k in ('width_m','height_m','depth_m')):
            backlog.append({'id':ident,'category_id':item['category_id'],'reason':'Missing or conflicting dimensional envelope','note':dim['axis_note']});continue
        if family not in EQUIPMENT|{'profile','par','fresnel','blinder','batten','strobe'}:
            backlog.append({'id':ident,'category_id':item['category_id'],'reason':'Model family not implemented: '+family});continue
        local=item.get('reference_image_file') or item.get('image_file') or (cached_reference(item['images'][0]) if item['images'] else None)
        if not local and not item['images']:
            backlog.append({'id':ident,'category_id':item['category_id'],'reason':'No reviewable exact-product reference image'});continue
        data={k:v for k,v in item['data'].items() if v is not None}
        data['dimensions']=dim;data['research_evidence']=item['evidence']
        data['control_path']=data.get('control_path','See source-backed protocol list; compatibility and control system are not implemented.')
        row={k:item[k] for k in ('name','model_number','manufacturer','type','subtype','url')}
        row.update(data=json.dumps(data,ensure_ascii=False),images=json.dumps(item['images']),expansion_batch='taxonomy',category_id=item['category_id'],control_path=data['control_path'])
        folder=ROOT/'assets/fixtures'/ident;folder.mkdir(parents=True,exist_ok=True)
        _,record=base.record_for(row,dim,folder,False)
        for ev in item['evidence']:
            found=next((s for s in record['sources'] if s['url']==ev['url']),None)
            if found is None:
                found={'id':f'evidence-{len(record["sources"])+1}','url':ev['url'],'reuse_status':'unknown'};record['sources'].append(found)
            found.update(kind=source_kind(ev),title=ev['title'],accessed_at=ev.get('accessed_at','2026-09-30'),document_revision=ev.get('document_revision'),locator=ev.get('locator',''))
            if ev.get('file') and (ROOT/ev['file']).is_file():
                source_path=ROOT/ev['file'];target=folder/'sources'/source_path.name
                shutil.copy2(source_path,target);found.update(file=target.relative_to(folder).as_posix(),sha256=hashlib.sha256(target.read_bytes()).hexdigest())
        sids=[s['id'] for s in record['sources']]
        for axis in ('width','height','depth'):
            record['dimensions'][axis].update(source_ids=sids,note=dim['axis_note'])
        pose=dim['reference_pose'];record['dimensions']['reference_pose']=pose
        model=record['model'];model.update(status='not_built',reference_pose=pose,artifacts=[],assumptions=['Original image-informed procedural model, not manufacturer CAD.',dim['axis_note'],'Small details are estimates; neutral envelope is not a swept volume, safety distance or structural/electrical certification.'])
        record['status']='researched'
        record['verification']['notes']=['Model generation and OpenUSD validation pending. No device or hardware tests.']
        record['equipment']={'primary_category':item['category_id'],'control_path':data['control_path'],'physical_asset_only':True,'source_data':data}
        profile={**item['modeling'],'family':family}
        if family in EQUIPMENT:profile['generator']='equipment'
        profile['output_kind']=OUTLETS.get(family,'none' if family in PASSIVE else 'light')
        url=item['images'][0] if item['images'] else item['url']
        if local and any(k in Path(local).stem for k in ('dimensions','page','sheet-')):
            url=item.get('reference_image_url') or next((e['url'] for e in item['evidence'] if '.pdf' in e['url'].lower()),item['url'])
        ext=Path(urlparse(url).path).suffix.lower()
        if local:ext=Path(local).suffix.lower()
        if ext not in ('.jpg','.png','.jpeg','.webp'):ext='.jpg'
        image=folder/'sources'/('product-reference'+ext)
        try:
            if local:shutil.copy2(ROOT/local,image)
            elif not image.exists():fetch(url,image)
            subprocess.run(['magick','identify',str(image)],capture_output=True,check=True)
        except Exception as e:
            backlog.append({'id':ident,'category_id':item['category_id'],'reason':'Reference image acquisition failed','error':str(e)});continue
        image_kind='secondary' if item['name']=='NYX Bulb' else 'manufacturer_asset'
        record['sources'].append({'id':'product-reference','url':url,'title':item['name']+' visual reference','kind':image_kind,'accessed_at':'2026-09-30','document_revision':None,'locator':item.get('reference_image_locator','Exact-model reference reviewed during category acquisition; rights and reuse remain unknown.'),'reuse_status':'unknown','file':image.relative_to(folder).as_posix(),'sha256':hashlib.sha256(image.read_bytes()).hexdigest()})
        record['revision_notes']=['Category-coverage acquisition: exact product, technical evidence, control path and high-detail build profile staged.']
        dump(folder/'fixture.json',record);base.write_note(folder,row,record)
        rows.append(row);seen.add(ident);profiles[ident]=profile;dimsmap[item['manufacturer']+'|'+item['name']]=dim;added.append(ident)
        dump(PROFILES,profiles);dump(base.MAP,dimsmap);sync_csv(rows)
        print('Imported',ident,flush=True)
    dump(ROOT/'research/fixtures/taxonomy/import-backlog.json',backlog)
    print(json.dumps({'added':added,'pending':backlog},indent=2))

if __name__=='__main__':main()
