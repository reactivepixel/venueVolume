#!/usr/bin/env python3
"""Create additive RealityKit rigs from reviewed USDZ geometry; preserve source meshes.

Run with OpenUSD Python (on Arch: LD_PRELOAD=/usr/lib/libjemalloc.so.2 python3 ...).
No hardware DMX mapping is generated. Re-run after adding a library asset.
"""
import argparse
import csv
import hashlib
import json
import shutil
from collections import Counter
from pathlib import Path
from pxr import Usd, UsdGeom

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / 'apps/visionos'
LIB = ROOT / 'assets/fixtures'

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')

def eligible_records():
    return [p for p in sorted(LIB.glob('*/*/fixture.json'))
            if json.loads(p.read_text())['model']['status'] == 'validated']

def build(record_path):
    record = json.loads(record_path.read_text())
    model = record['model']; profile = model['profile']; family = profile['family']
    folder = record_path.parent
    runtime = next(a for a in model['artifacts'] if a['role'] == 'runtime')
    source = folder / runtime['file']
    # Never copy an unreviewed manual change over a bundled asset.
    for artifact in model['artifacts']:
        if digest(folder / artifact['file']) != artifact['sha256']:
            raise ValueError(f'Manual edit needs review: {folder / artifact["file"]}')
    stage = Usd.Stage.Open(str(source))
    assert stage and UsdGeom.GetStageMetersPerUnit(stage) == 1 and UsdGeom.GetStageUpAxis(stage) == 'Y'
    paths = {str(p.GetPath()) for p in stage.Traverse()}
    parts = {p['prim_path'].rsplit('/', 1)[-1]: p for p in model['parts']}
    joints = []; emitters = []; head_aim = False

    def joint(ident, label, members, pivot, axis, channel, travel, parent=None, mode='motor', continuous=False):
        assert all(m in paths for m in members), (record['id'], members)
        assert parent is None or any(j['id'] == parent for j in joints)
        assert 0 <= channel < 16
        joints.append(dict(id=ident, label=label, parent=parent, members=members, pivot=pivot,
                           axis=axis, channel=channel, travel=travel, continuous=continuous, mode=mode))

    def emitter(position, parent=None):
        emitters.append(dict(parent=parent, position=position, axis=[0, 0, -1]))

    def p(name): return parts[name]['pivot_m']
    def path(name): return parts[name]['prim_path']

    if family.startswith('moving_') or family == 'tracking_camera':
        head = 'Camera' if family == 'tracking_camera' else 'Head'
        joint('pan', 'Pan', [path('Yoke')], p('Yoke'), [0, 1, 0], 4, 270)
        moving_head = [path(head)]
        if family == 'tracking_camera':
            moving_head = [str(q.GetPath()) for q in stage.GetPrimAtPath(path(head)).GetChildren()
                           if not q.GetName().startswith('Base_cooling_vent')]
        joint('tilt', 'Tilt', moving_head, p(head), [1, 0, 0], 5, 120, 'pan')
        head_aim = bool(model.get('emitters'))
        for e in model.get('emitters', []): emitter(e['position_m'], 'tilt')
    elif profile.get('dual_movers'):
        for i in range(1,3):
            yoke=f'Yoke_{i:02d}';head=f'Head_{i:02d}';pan=f'pan_{i}';tilt=f'tilt_{i}'
            joint(pan,f'Head {i} pan',[path(yoke)],p(yoke),[0,1,0],7+(i-1)*2,270)
            joint(tilt,f'Head {i} tilt',[path(head)],p(head),[1,0,0],8+(i-1)*2,120,pan)
            lens=next(q for q in stage.Traverse() if str(q.GetPath()).startswith(path(head)+'/Lens/Independent_spot_glass'))
            box=UsdGeom.BBoxCache(0,['default']).ComputeWorldBound(lens).ComputeAlignedBox()
            center=list(box.GetMidpoint());center[2]=box.GetMin()[2]-.002
            emitter(center,tilt)
    elif profile.get('multi_heads'):
        for i, name in enumerate(sorted(n for n in parts if n.startswith('Head_'))):
            moving_head = [str(q.GetPath()) for q in stage.GetPrimAtPath(path(name)).GetChildren()
                           if not q.GetName().startswith(('Head_support_cheek', 'Head_pivot_cap'))]
            mode=profile.get('head_mode','motor')
            joint(name, f'Head {i+1} tilt'+(' (manual)' if mode=='manual' else ''), moving_head, p(name), [1, 0, 0], 7+i, 120, mode=mode)
            # Each modeled optical module has its own beam, placed at its front optic.
            lens = next(q for q in stage.Traverse() if str(q.GetPath()).startswith(path(name)+'/Independent_beam_optic'))
            box = UsdGeom.BBoxCache(0, ['default']).ComputeWorldBound(lens).ComputeAlignedBox()
            center = list(box.GetMidpoint()); center[2] = box.GetMin()[2] - 0.002
            emitter(center, name)
    elif profile.get('tilting') or profile.get('manual_tilt'):
        # The authored Body combines the motor base and moving housing. Resolve
        # exact mesh paths so the base and supporting brackets stay at rest.
        fixed = ('Floor_bracket', 'Bracket_arm', 'Motor_base')
        members = [str(q.GetPath()) for q in stage.GetPrimAtPath(path('Body')).GetChildren()
                   if q.IsA(UsdGeom.Mesh) and not q.GetName().startswith(fixed)] + [path('Lens')]
        manual=profile.get('manual_tilt',False)
        joint('tilt', 'Bracket tilt (manual)' if manual else 'Tilt', members, p('Yoke'), [1, 0, 0], 5, 120, mode='manual' if manual else 'motor')
        for e in model.get('emitters', []): emitter(e['position_m'], 'tilt')
    elif family == 'scanner':
        joint('pan', 'Mirror pan', [], p('Mirror'), [0, 1, 0], 4, 60)
        joint('tilt', 'Mirror tilt', [path('Mirror')], p('Mirror'), [1, 0, 0], 5, 60, 'pan')
        # A visual ray follows the mirror. Reflected optical calibration is not
        # established, so automatic head targeting remains unavailable.
        for e in model.get('emitters', []): emitter(e['position_m'], 'tilt')
    elif family == 'fan':
        joint('tilt', 'Bracket tilt (manual)', [path('Body'), path('Guard')], p('Body'), [1, 0, 0], 5, 120, mode='manual')
        joint('rotor', 'Fan speed', [path('Rotor')], p('Rotor'), [0, 0, -1], 7, 720, 'tilt', continuous=True)
    elif family == 'mirror_motor':
        members = sorted(q for q in paths if '/Output_shaft' in q)
        joint('shaft', 'Shaft speed', members, [0, 0, 0], [0, 1, 0], 7, 36, continuous=True, mode='manual')
    elif family == 'mirror_ball':
        members = [str(q.GetPath()) for q in stage.GetPrimAtPath(path('Body')).GetChildren()
                   if q.IsA(UsdGeom.Mesh) and not any(s in q.GetName().lower() for s in ('loop', 'eye', 'suspension'))]
        joint('ball', 'Ball speed', members, [0, model['bounds_m']['max'][1]/2, 0], [0, 1, 0], 7, 36, continuous=True, mode='manual')
    elif 'Yoke' in parts and 'Lens' in parts and family in ('par', 'profile', 'fresnel', 'pc', 'par_can', 'followspot', 'flood', 'cyc', 'blinder'):
        joint('tilt', 'Bracket tilt (manual)', [path('Body'), path('Lens')], p('Yoke'), [1, 0, 0], 5, 120, mode='manual')
        for e in model.get('emitters', []): emitter(e['position_m'], 'tilt')
    else:
        for e in model.get('emitters', []): emitter(e['position_m'])

    resource = 'FixtureAssets/RogueR1X/fixture.usdz' if record['id'] == 'chauvet-professional/rogue-r1x-spot' else 'FixtureAssets/Catalog/' + record['id'] + '/fixture.usdz'
    descriptor = dict(id=record['id'], name=record['identity']['model'], manufacturer=record['identity']['manufacturer'],
                      family=family, resource=resource, sha256=runtime['sha256'], boundsMin=model['bounds_m']['min'],
                      boundsMax=model['bounds_m']['max'], joints=joints, emitters=emitters, headAim=head_aim,
                      notes='VV Preview 16 simulation. Pivots and travel are visual estimates; manufacturer DMX and mechanical limits are not mapped. Light output is illustrative.' if joints or emitters else 'Static equipment model.')
    review_file=ROOT/'research/fixtures/expansion-v2/visual-review-issues.json'
    review=json.loads(review_file.read_text()) if review_file.exists() else {}
    if record['id'] in review:descriptor['notes']+=' Visual correction pending: '+review[record['id']]+'.'
    rig_path = folder / 'models/rig.json'
    save(rig_path, dict(schema_version=1, state='runtime_integrated_native_validation_pending', source_usdz_sha256=runtime['sha256'],
                        native_validation='pending', descriptor=descriptor))
    destination = APP / 'VenueVolume' / resource
    destination.parent.mkdir(parents=True, exist_ok=True)
    if not destination.exists() or digest(destination) != runtime['sha256']: shutil.copy2(source, destination)
    return descriptor

def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--check', action='store_true'); args = parser.parse_args()
    if args.check:
        catalog = json.loads((LIB/'runtime-catalog.json').read_text())
        records = sorted(p.parent.relative_to(LIB).as_posix() for p in eligible_records())
        assert sorted(a['id'] for a in catalog) == records
        for item in catalog:
            assert digest(APP/'VenueVolume'/item['resource']) == item['sha256']
            assert digest(LIB/item['id']/'models/fixture.usdz') == item['sha256']
            assert json.loads((LIB/item['id']/'models/rig.json').read_text())['descriptor'] == item
        print(f'PASS: {len(catalog)} bundled assets and rig records match the library.'); return
    catalog = []; failures = {}
    for path in eligible_records():
        try: catalog.append(build(path))
        except Exception as error:
            failures[path.parent.relative_to(LIB).as_posix()] = str(error)
    save(LIB/'research/rig-build-errors.json', failures)
    if failures:
        raise RuntimeError(f'{len(failures)} rig builds failed; previous runtime catalog preserved. See rig-build-errors.json.')
    save(LIB/'runtime-catalog.json', catalog)
    generated = APP/'Core/Sources/VenueVolumeCore/GeneratedFixtureCatalog.swift'
    generated.write_text('// Generated by research/fixtures/build_runtime_catalog.py. Do not edit.\n'
                         'let generatedFixtureCatalog = #"""\n' + json.dumps(catalog, separators=(',', ':'), ensure_ascii=False) + '\n"""#\n')
    summary = dict(assets=len(catalog), articulated=sum(bool(a['joints']) for a in catalog),
                   joints=sum(len(a['joints']) for a in catalog), families=dict(Counter(a['family'] for a in catalog)),
                   native_validation='pending', rig_files=[f'assets/fixtures/{a["id"]}/models/rig.json' for a in catalog])
    save(LIB/'research/articulation-rollout.json', summary)
    # These CSVs are generated catalog indexes. Preserve every existing field,
    # source value and research-only row while adding the runtime asset state.
    by_id = {a['id']: a for a in catalog}
    for filename in ('major-manufacturer-fixtures.csv', 'show-equipment-catalog.csv'):
        path = LIB/'research'/filename
        with path.open(newline='') as stream:
            reader = csv.DictReader(stream); fields = list(reader.fieldnames); rows = list(reader)
        additions = ['animation_state', 'rig_asset', 'rig_joint_count', 'visionos_asset']
        fields += [f for f in additions if f not in fields]
        for row in rows:
            ident = row.get('asset_root', '').removeprefix('assets/fixtures/')
            item = by_id.get(ident)
            if item:
                row.update(animation_state='rigged_native_validation_pending' if item['joints'] else 'static_native_validation_pending',
                           rig_asset=f'assets/fixtures/{ident}/models/rig.json', rig_joint_count=len(item['joints']),
                           visionos_asset='apps/visionos/VenueVolume/'+item['resource'])
            else:
                row.update(animation_state='research_only', rig_asset='', rig_joint_count='', visionos_asset='')
        with path.open('w', newline='') as stream:
            writer = csv.DictWriter(stream, fieldnames=fields, lineterminator='\n'); writer.writeheader(); writer.writerows(rows)
    print(json.dumps({k:v for k,v in summary.items() if k not in ('rig_files','families')}, indent=2))

if __name__ == '__main__': main()
