"""Apply source-review corrections consistently to research, records and model profiles."""
import csv,json,hashlib,shutil
from pathlib import Path
from build_detailed_catalog import ROOT,CSV,PROFILES,dump,fid,sync_csv
profiles=json.loads(PROFILES.read_text());rows=list(csv.DictReader(CSV.open()))
changes={'martin-professional-harman/mac-aura':{'lens_count':19,'aura':True,'body_style':'19-lens RGBW moving wash with secondary Aura backlight','notes':'Official Martin optics table specifies 19 x 10 W RGBW; secondary Aura illumination is not counted as lenses.'},'glp/jdc-line-1000':{'diffuser':True},'elation-professional/vbar-270':{'overhead_yoke':True}}
for ident,change in changes.items():profiles[ident].update(change)
dump(PROFILES,profiles)
for file in (ROOT/'research/fixtures/expansion').glob('*.json'):
    items=json.loads(file.read_text())
    for item in items:
        ident=fid(item)
        if ident in changes:item['modeling'].update(changes[ident])
        if ident=='claypaky/volero-wave':
            dim=item['dimensions'];dim.update(height_m=.329,depth_m=.182,axis_note='Claypaky datasheet 11/2022 page 1 drawing: 1000 mm span, 329 mm vertical height and 182 mm head sweep depth; distributor-hosted manufacturer document visually checked.')
            item['evidence']=[e for e in item['evidence'] if 'datablad_claypaky_volerowave' not in e['url']]
            item['evidence'].append({'url':'https://ltb.no/media/multicase/documents/claypaky/datablad_claypaky_volerowave_11.2022.pdf','title':'Claypaky Volero Wave datasheet 11/2022 (distributor mirror)','locator':'Page 1 dimensioned side and isometric drawings','accessed_at':'2026-09-30'})
            folder=ROOT/'assets/fixtures'/ident;rp=folder/'fixture.json';record=json.loads(rp.read_text())
            dest=folder/'sources/volero-datasheet-11-2022.pdf'
            if not dest.exists():shutil.copy2('/tmp/volero-datasheet.pdf',dest)
            record['sources']=[s for s in record['sources'] if s['id']!='dimension-drawing-review']
            record['sources'].append({'id':'dimension-drawing-review','url':item['evidence'][-1]['url'],'title':item['evidence'][-1]['title'],'kind':'manufacturer_drawing','accessed_at':'2026-09-30','document_revision':'11/2022','locator':item['evidence'][-1]['locator'],'reuse_status':'reference_only','file':dest.relative_to(folder).as_posix(),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
            for key in ('height','depth'):
                record['dimensions'][key].update(value=dim[key+'_m'],status='documented',source_ids=['dimension-drawing-review'],note=dim['axis_note'])
            record['revision_notes'].append('Visual drawing review corrected transposed height/depth: 329 mm high, 182 mm deep.')
            dump(rp,record)
            for row in rows:
                if fid(row)==ident:
                    data=json.loads(row['data']);data['dimensions']=dim;data['research_evidence']=item['evidence'];row['data']=json.dumps(data,ensure_ascii=False)
            # This file's path is provided by the original importer, not hardcoded.
            import generate_fixture_assets as base
            dims=json.loads(base.MAP.read_text());dims[item['manufacturer']+'|'+item['name']]=dim;dump(base.MAP,dims)
    dump(file,items)
sync_csv(rows)
