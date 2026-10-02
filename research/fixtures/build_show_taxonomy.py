#!/usr/bin/env python3
"""Publish stable classification, an honest gap register, and a browsable hierarchy."""
import csv,html,json
from collections import Counter
from pathlib import Path
from build_detailed_catalog import ROOT,CSV,PROFILES,fid,dump,sync_csv
from import_show_equipment import read_candidates,ALIASES,cached_reference

DEFINITION=ROOT/'research/fixtures/taxonomy/show-equipment-hierarchy.json'
OUT=ROOT/'assets/fixtures/research'
FAMILY_CATEGORY={'followspot':'lighting.followspot','pc':'lighting.static.pc','par_can':'lighting.static.par','cyc':'lighting.static.cyc','uv':'lighting.static.uv','practical':'lighting.static.practical','tube':'lighting.static.tube','pixel_strip':'lighting.static.pixel_tape','scanner':'lighting.moving.scanner','mirror_ball':'lighting.effects.mirror_ball','laser':'lighting.effects.laser','pinspot':'lighting.static.beam','flood':'lighting.static.flood','blinder':'lighting.effects.blinder','fogger':'atmosphere.fog','low_fog':'atmosphere.low_fog','jet':'atmosphere.fog_jet','fan':'atmosphere.fan','bubble':'effects.bubble','snow':'effects.snow','confetti':'effects.confetti','co2_jet':'effects.co2','spark':'effects.spark','flame':'effects.flame','console':'control.console','node':'control.node','dimmer':'power.dimmer','power':'power.distribution','truss':'rigging.truss','stand':'rigging.stand','clamp':'rigging.clamp','led_panel':'video.panel','projector':'video.projector','screen':'video.screen','media_server':'video.processor','deck':'scenic.deck'}

def classify(row,profile):
    if profile.get('category_id'):return profile['category_id']
    f=ALIASES.get(profile['family'],profile['family']);name=row['name'].lower();text=(row['type']+' '+row['subtype']).lower()
    if f=='splitter':return 'control.distribution'
    if f in ('pixel_controller','pixel_driver'):return 'control.pixel'
    if f=='lens_tube':return 'accessories.optic'
    if f=='iris':return 'accessories.mask'
    if f=='gobo':return 'accessories.gobo'
    if f=='filter_sheet':return 'accessories.color'
    if f=='drape':return 'scenic.drape'
    if f=='power_supply':return 'power.distribution'
    if f=='tracking_camera':return 'control.tracking'
    if f=='data_connector':return 'control.cable'
    if f=='power_connector':return 'power.cable'
    if f=='connector':return 'power.cable' if 'powerCON' in row['name'] else 'control.cable'
    if f=='mirror_motor':return 'lighting.effects.mirror_motor'
    if f=='water_jet':return 'effects.water'
    if f=='fluid_container':return 'accessories.fluid'
    if f=='co2_supply':return 'accessories.gas'
    if f=='safety_wire':return 'rigging.secondary'
    if f=='safety_hardware':return 'rigging.secondary'
    if f=='hoist':return 'rigging.hoist'
    if f=='hazer':return 'atmosphere.haze_oil' if row['manufacturer']=='MDG' or 'oil' in text else 'atmosphere.haze_water'
    if f in FAMILY_CATEGORY:return FAMILY_CATEGORY[f]
    if f=='batten':
        if profile.get('spot_bar'):return 'lighting.static.batten'
        if profile.get('tilting') or profile.get('multi_heads') or profile.get('dual_movers') or name in ('impression x4 bar 20','impression x5 bar 1000'):return 'lighting.moving.batten'
        if 'strobe' in text:return 'lighting.effects.strobe'
        return 'lighting.static.batten'
    if f=='strobe':return 'lighting.effects.strobe'
    if f=='multi_effect':return 'lighting.effects.multi_effect'
    if f=='fresnel':return 'lighting.static.fresnel'
    if f=='profile':return 'lighting.static.profile'
    if f=='par':return 'lighting.static.par'
    if f.startswith('moving_'):
        if 'hybrid' in text or name in ('megapointe','pointe','proteus radius','sharpy plus','sharpy plus aqua'):return 'lighting.moving.hybrid'
        if 'wash' in text or 'wash' in name or name in ('mac one','ledbeam 350','spiider','mini-b'):return 'lighting.moving.wash'
        if 'profile' in text or 'framing' in text or name in ('forte','iforte','mac viper performance','mac ultra performance'):return 'lighting.moving.profile'
        if 'beam' in text or name in ('sharpy','dartz 360','hydro beam x1'):return 'lighting.moving.beam'
        return 'lighting.moving.spot'
    raise ValueError('Unmapped equipment: '+fid(row)+' '+f)

def main():
    definition=json.loads(DEFINITION.read_text());cats=definition['categories'];byid={c['id']:c for c in cats}
    assert len(byid)==len(cats)
    children={c['id']:[] for c in cats}
    for c in cats:
        if c['parent_id'] is not None:
            assert c['parent_id'] in byid;children[c['parent_id']].append(c['id'])
    def path(ident):
        chain=[];visited=set()
        while ident:
            assert ident not in visited,'Category cycle';visited.add(ident);chain.append(byid[ident]['name']);ident=byid[ident]['parent_id']
        return list(reversed(chain))
    for c in cats:c['path']=path(c['id']);c['is_leaf']=not children[c['id']]
    rows=list(csv.DictReader(CSV.open()));profiles=json.loads(PROFILES.read_text());items=[]
    for row in rows:
        ident=fid(row);category=classify(row,profiles[ident]);assert category in byid and not children[category]
        rpath=ROOT/row['fixture_record'];record=json.loads(rpath.read_text());model=record['model']
        complete=model.get('status')=='validated' and all((ROOT/row[k]).is_file() for k in ('blend_asset','usdz_asset','preview_asset'))
        if complete:
            report=json.loads((ROOT/row['validation_report']).read_text());parity=json.loads((ROOT/row['parity_report']).read_text())
            complete=report['passed'] and parity['passed']
        tags=[];text=(row['type']+' '+row['subtype']).lower();data=json.loads(row['data'])
        for word,label in [('strobe','strobe capable'),('blinder','blinder capable'),('pixel','pixel control'),('ip6','weather-rated variant'),('legacy','legacy model')]:
            if word in text:tags.append(label)
        if 'hybrid' in category:tags+=['multi-role optics']
        control=data.get('control_path') or 'Source protocol list: '+', '.join(data.get('protocols') or [])
        row.update(category_id=category,category_path=' > '.join(path(category)),category_tags=json.dumps(tags),control_path=control)
        record['classification']={'taxonomy_version':1,'primary_category':category,'category_path':path(category),'use_tags':tags,'method':'Reviewed primary function; capabilities do not create duplicate inventory entries.'}
        if 'equipment' in record:record['equipment']['primary_category']=category
        dump(rpath,record)
        items.append({'id':ident,'name':row['name'],'manufacturer':row['manufacturer'],'category_id':category,'category_path':row['category_path'],'tags':tags,'state':record['status'],'model_state':model['status'],'asset_complete':complete,'preview':'../'+ident+'/previews/three-quarter.png','asset_root':'../'+ident+'/','official_url':row['url'],'control_path':control,'dimensions':' × '.join(f'{record["dimensions"][a]["value"]:g} m {b}' for a,b in [('width','W'),('height','H'),('depth','D')]),'pose':record['dimensions']['reference_pose'],'dimension_caveat':any(record['dimensions'][a]['status']!='documented' for a in ('width','height','depth')) or bool(record['unresolved'])})
    pending=json.loads((ROOT/'research/fixtures/taxonomy/import-backlog.json').read_text()) if (ROOT/'research/fixtures/taxonomy/import-backlog.json').exists() else []
    all_candidates=read_candidates()
    candidates={fid(r):r for r in all_candidates}
    from expand_catalog import candidates as expansion_candidates, issues, load_ledger
    expansion=expansion_candidates(); candidates.update(expansion)
    ledger=load_ledger()
    packaged={fid(row) for row in rows}
    for ident,candidate in expansion.items():
        if ident in packaged:continue
        reasons=ledger.get(ident,{}).get('errors') or issues(candidate) or ['Asset pipeline has not completed for this model']
        pending.append(dict(id=ident,reason='; '.join(reasons),category_id='lighting.moving.spot',stage=ledger.get(ident,{}).get('stage','research')))
    for p in pending:
        if p['id'] in candidates:
            candidate=candidates[p['id']]
            p['category_id']=classify(candidate,candidate['modeling'])
            p['official_url']=candidate['url']
            p.update(name=candidate['name'],manufacturer=candidate['manufacturer'],source_images=candidate['images'])
            reference=candidate.get('reference_image_file') or candidate.get('image_file') or (cached_reference(candidate['images'][0]) if candidate['images'] else None)
            p['reference_asset']=reference if reference and (ROOT/reference).is_file() else ''
    for c in reversed(cats):
        direct=[i for i in items if i['category_id']==c['id']]
        c['asset_ids']=[i['id'] for i in direct if i['asset_complete']]
        c['asset_count']=len(c['asset_ids'])+sum(byid[ch]['asset_count'] for ch in children[c['id']])
        c['research_candidates']=[p for p in pending if p['category_id']==c['id']]
        c['coverage']='represented' if c['asset_count'] else ('research_pending' if c['research_candidates'] else 'missing')
        c['model_catalog_exhaustive']=False
    leaves=[c for c in cats if c['is_leaf']];gaps=[c for c in leaves if not c['asset_count']]
    result={**definition,'summary':{'asset_count':len(items),'manufacturer_count':len({i['manufacturer'] for i in items}),'terminal_categories':len(leaves),'represented_categories':len(leaves)-len(gaps),'unrepresented_categories':len(gaps),'all_assets_packaged':all(i['asset_complete'] for i in items),'every_category_covered':not gaps,'exhaustive_model_catalog':False},'items':items,'pending_acquisition':pending}
    dump(OUT/'show-equipment-taxonomy.json',result);sync_csv(rows)
    # Complete acquisition view includes research-only rows and deliberately empty
    # asset locations. The historical fixture CSV remains the packaged asset list.
    combined=[dict(row) for row in rows]
    for p in pending:
        candidate=candidates[p['id']];category=p['category_id']
        combined.append({k:candidate[k] for k in ('name','model_number','manufacturer','type','subtype','url')}|{'data':json.dumps({'specifications':candidate['data'],'dimensions':candidate['dimensions'],'evidence':candidate['evidence'],'blocking_issue':p},ensure_ascii=False),'images':json.dumps(candidate['images']),'asset_state':'research_only','model_state':'not_built','category_id':category,'category_path':' > '.join(path(category)),'control_path':candidate['data'].get('control_path','See acquisition record'),'expansion_batch':candidate.get('_batch','taxonomy'),'asset_blocker':p['reason']})
    for row in combined:
        candidate=candidates.get(fid(row),{})
        reference=candidate.get('reference_image_file') or candidate.get('image_file')
        row['reference_asset']=reference if reference and (ROOT/reference).is_file() else ''
    fields=list(dict.fromkeys(k for row in combined for k in row))
    with (OUT/'show-equipment-catalog.csv').open('w',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=fields,lineterminator='\n');writer.writeheader();writer.writerows(combined)
    flat=[{k:c.get(k,'') for k in ('id','parent_id','name','is_leaf','definition','coverage','asset_count')}|{'path':' > '.join(c['path']),'asset_ids':json.dumps(c['asset_ids']),'research_candidates':json.dumps(c['research_candidates'],ensure_ascii=False)} for c in cats]
    with (OUT/'show-equipment-hierarchy.csv').open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(flat[0]),lineterminator='\n');w.writeheader();w.writerows(flat)
    write_note(result,gaps)
    template=(ROOT/'research/fixtures/taxonomy/explorer-template.html').read_text()
    template=template.replace('href="major-manufacturer-fixtures.csv">Product CSV','href="show-equipment-catalog.csv">Product CSV (including pending)')
    template=template.replace('</style>','label{min-width:0;max-width:100%}select,input{min-width:0;max-width:100%}@media(max-width:600px){.filters label{width:100%;flex-direction:column;align-items:stretch}article h3{overflow-wrap:anywhere}}</style>')
    (OUT/'show-equipment.html').write_text(template.replace('/*__DATA__*/',json.dumps(result,ensure_ascii=False).replace('</','<\\/')))
    print(json.dumps(result['summary'],indent=2))

def write_note(result,gaps):
    s=result['summary'];lines=['# Show equipment hierarchy','',f'{s["asset_count"]} modeled products from {s["manufacturer_count"]} manufacturers. {s["represented_categories"]} of {s["terminal_categories"]} terminal categories have packaged representative assets; {s["unrepresented_categories"]} remain open. This is not an exhaustive model/manufacturer catalog.','', '[Browse hierarchy, gaps and renders](../../assets/fixtures/research/show-equipment.html) · [Hierarchy CSV](../../assets/fixtures/research/show-equipment-hierarchy.csv) · [Fixture CSV](../../assets/fixtures/research/major-manufacturer-fixtures.csv) · [Machine-readable taxonomy](../../assets/fixtures/research/show-equipment-taxonomy.json)','', '## Design decisions','', 'Equipment function drives the hierarchy. LED/tungsten/discharge, DMX/network/external dimmer, mounting, weather rating, lifecycle and venue scale remain facets. A fixture has one primary category and optional use tags. This prevents double-counting hybrid fixtures and keeps older theatre stock discoverable alongside modern tour equipment.','', 'The taxonomy uses practitioner vocabulary, not a claimed industry standard. Forum posts informed distinctions such as wash versus profile, ACL beam versus audience blinder, and haze versus fog. Manufacturer documents supply technical facts; forum advice does not establish performance, fluid compatibility or safety.','', '## Categories and asset coverage','', '| Category | Representative assets | Coverage |','| --- | ---: | --- |']
    for c in result['categories']:
        if c['is_leaf']:
            paths=', '.join(f'[{ident}](entries/{ident}.md)' for ident in c['asset_ids'][:3])
            if len(c['asset_ids'])>3:paths+=f' (+{len(c["asset_ids"])-3} more in explorer)'
            lines.append(f'| {" → ".join(c["path"])} | {c["asset_count"]} | {paths or c["coverage"]} |')
    lines+=['','## Remaining acquisition queue','', 'Missing categories are deliberately visible. A downloaded image, a named candidate, an embedded accessory shape, or a generic proxy does not count as an exact product asset. Custom scenery additionally needs production-specific dimensions.','']
    for c in gaps:
        reasons='; '.join(p['reason'] for p in c['research_candidates']) or 'Exact documented representative and model still required.'
        lines.append(f'- {" → ".join(c["path"])}: {reasons}')
    lines+=['','## Research sources','', 'The [forum research ledger](../../research/fixtures/taxonomy/forum-research.json) contains the complete source list, access date, concise observations and limitations. Selected discussions:','', '- [ControlBooth: blinders and ACL replacements](https://www.controlbooth.com/threads/blinders-and-acl-replacements.46845/) — different functions can share source technology.','- [Blue Room: spot to wash](https://www.blue-room.org.uk/topic/56135-spot-to-wash/) — profile and wash remain distinct optical roles.','- [r/lightingdesign: fog versus haze](https://www.reddit.com/r/lightingdesign/comments/t97d22/fog_vs_haze/) — atmosphere belongs in the design inventory, with separate fog and haze machines.','- [ControlBooth: options for LED striplights](https://www.controlbooth.com/threads/options-for-led-striplights.41643/) — cyc, scenery and audience uses overlap without making three different products.','', '## Representation and limits','', 'Models are original, image-informed procedural approximations with editable Blender sources, full-geometry USDZ and four orthographic/angled previews. Exact dimensional evidence and pose caveats remain in each record. Structural and saved-geometry parity tests do not prove manufacturer-CAD fidelity, load capability, photometry, RealityKit rendering or physical hardware operation. No live device commands are implemented.','', 'Laser, flame, spark, pressurized-gas, suspended equipment and electrical assets are physical visualization records only. Operational approval, suitable personnel and venue-specific safety assessment remain separate; no firing maps, safety distances or load approval are inferred.','', 'Control addresses, cues, timecode, haze density, video content and particle simulation are planning objects, not manufacturer fixture models. Audio/backline remains a separate potential scope.','']
    lines+=['## Validation and reproduction','',
        '[Saved Blender/USDZ parity](../../assets/fixtures/research/geometry-audit.json) · [Catalog manifest](../../assets/fixtures/research/catalog-validation.json) · [Hierarchy/browser checks](../../assets/fixtures/research/taxonomy-validation.json)', '',
        'The acquisition subagents used GPT-6 Luna at medium reasoning. Integration reviewed official product photos and dimensional drawings, then ran the create-venue-fixture record/build/validation workflow per accepted product. The skill preserves unknowns, estimated poses, evidence, revisions and editable authoring geometry.', '',
        'Refresh order: `import_show_equipment.py`, `build_detailed_catalog.py`, Blender `audit_geometry.py`, `finalize_detailed_catalog.py`, then `build_show_taxonomy.py` (all under `research/fixtures/`). Rebuild the library index after classification. Run `test_show_taxonomy.py`, `test_gallery.mjs` and `test_taxonomy.mjs`; browser checks need the design-studio Playwright dependency and Chromium. Existing artifacts with changed hashes are protected from overwrite.', '',
        'The original ten-maker cap applied to the lighting acquisition batch. The expanded show-equipment scope includes specialist manufacturers of atmosphere, control, video, power, rigging and consumables. No market-share ranking or exhaustive worldwide model coverage is claimed.', '']
    note='\n'.join(lines).replace('[Fixture CSV](../../assets/fixtures/research/major-manufacturer-fixtures.csv)','[Complete product CSV, including research-only rows](../../assets/fixtures/research/show-equipment-catalog.csv)')
    (ROOT/'docs/08 Fixture Library/Show Equipment Hierarchy.md').write_text(note)

if __name__=='__main__':main()
