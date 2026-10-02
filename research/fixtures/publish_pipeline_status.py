#!/usr/bin/env python3
"""Audit every CSV item and publish row-level errors and a complete review page.

Run after finalizing the model catalog, taxonomy and runtime rigs. A research row
is never promoted because a neighboring fixture or a family template succeeded.
"""
import csv
import hashlib
import json
import re
from collections import Counter
from pathlib import Path
from build_detailed_catalog import ROOT, fid, dump

OUT=ROOT/'assets/fixtures/research'

def visual_issues():
    path=ROOT/'research/fixtures/expansion-v2/visual-review-issues.json'
    return json.loads(path.read_text()) if path.exists() else {}

def read(path):
    with path.open(newline='') as stream:return list(csv.DictReader(stream))

def write(path,rows):
    fields=list(dict.fromkeys(k for row in rows for k in row))
    with path.open('w',newline='') as stream:
        writer=csv.DictWriter(stream,fieldnames=fields,lineterminator='\n')
        writer.writeheader();writer.writerows(rows)

def sentence(text):
    # CSV cells stay concise; full trace/evidence remains in the source ledger.
    text=re.sub(r'\s+',' ',str(text)).strip().rstrip('.')
    text=re.sub(r'(?<=[a-z)])\.\s+(?=[A-Z])','; ',text)
    if len(text)>650:text=text[:647].rsplit(' ',1)[0]+'…'
    return text+'.' if text else ''

def inspect(row):
    ident=fid(row);folder=ROOT/'assets/fixtures'/ident
    path=folder/'fixture.json';errors=[]
    if not path.exists() or not row.get('usdz_asset'):
        reason=row.get('asset_blocker') or 'A validated model package has not been produced'
        issue=json.loads(row.get('data') or '{}').get('blocking_issue',{})
        state='failed' if issue.get('stage') in ('model','record','rig') else 'blocked'
        return state,sentence(reason)
    try:
        record=json.loads(path.read_text());model=record['model']
        if model['status']!='validated':errors.append('The model has not passed exported-asset validation')
        for artifact in model['artifacts']:
            source=folder/artifact['file']
            if not source.is_file():errors.append('Missing artifact '+artifact['file'])
            elif hashlib.sha256(source.read_bytes()).hexdigest()!=artifact['sha256']:
                errors.append('Artifact differs from reviewed hash: '+artifact['file'])
        for name in ('usdz','parity','rig'):
            check=folder/'validation'/f'{name}.json'
            if not check.exists():errors.append(name+' validation has not run')
            elif not json.loads(check.read_text()).get('passed'):errors.append(name+' validation failed')
        rig_path=folder/'models/rig.json'
        if not rig_path.exists():errors.append('Runtime rig metadata is missing')
        else:
            rig=json.loads(rig_path.read_text());descriptor=rig['descriptor']
            bundled=ROOT/'apps/visionos/VenueVolume'/descriptor['resource']
            if not bundled.exists():errors.append('The visionOS runtime asset has not been bundled')
            elif hashlib.sha256(bundled.read_bytes()).hexdigest()!=descriptor['sha256']:
                errors.append('The bundled model does not match its rig descriptor')
        if errors:return 'failed',sentence('; '.join(errors))
        if ident in visual_issues():
            note=sentence(visual_issues()[ident])
            if rig.get('native_validation')!='passed':note+=' Native RealityKit validation is also pending on Mac.'
            return 'visual_review_pending',note
        if rig.get('native_validation')!='passed':
            return 'native_validation_pending','Local model, rig and bundle checks passed; native RealityKit validation for this catalog release is pending on Mac.'
        return 'complete',''
    except Exception as error:return 'failed',sentence('Pipeline audit could not complete: '+str(error))

def main():
    rows=read(OUT/'show-equipment-catalog.csv')
    assert len({fid(r) for r in rows})==len(rows),'Duplicate catalog identities'
    for row in rows:
        row['pipelineStatus'],row['pipelineErrors']=inspect(row)
    write(OUT/'show-equipment-catalog.csv',rows)
    byid={fid(r):r for r in rows}
    packaged=read(OUT/'major-manufacturer-fixtures.csv')
    for row in packaged:
        result=byid[fid(row)]
        row.update(pipelineStatus=result['pipelineStatus'],pipelineErrors=result['pipelineErrors'])
    write(OUT/'major-manufacturer-fixtures.csv',packaged)
    counts=Counter(r['pipelineStatus'] for r in rows)
    report=dict(rows=len(rows),packaged=len(packaged),manufacturers=len({r['manufacturer'] for r in rows}),
                statuses=dict(counts),exhaustive_manufacturer_catalog=False,
                note='Inventory expands from official sources; this is not a claim that all manufacturer models or regional variants are covered.',
                items=[dict(id=fid(r),status=r['pipelineStatus'],pipelineErrors=r['pipelineErrors']) for r in rows])
    dump(OUT/'pipeline-status.json',report)
    payload=json.dumps([dict(id=fid(r),name=r['name'],manufacturer=r['manufacturer'],type=r['type'],subtype=r['subtype'],
                            category=r.get('category_path',''),status=r['pipelineStatus'],error=r['pipelineErrors'],
                            url=r['url'],root=r.get('asset_root',''),image=r.get('preview_asset',''),
                            joints=r.get('rig_joint_count',''),record=r.get('fixture_record','')) for r in rows],ensure_ascii=False).replace('</','<\\/')
    template=(ROOT/'research/fixtures/pipeline-review-template.html').read_text()
    (OUT/'pipeline-review.html').write_text(template.replace('CATALOG_PAYLOAD',payload))
    print(json.dumps({k:v for k,v in report.items() if k!='items'},indent=2))

if __name__=='__main__':main()
