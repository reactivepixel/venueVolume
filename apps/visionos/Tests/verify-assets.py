"""Check that the shipped room and fixture match the reviewed repository artifacts."""
from pathlib import Path
import hashlib
import json

app = Path(__file__).resolve().parents[1]
repo = app.parents[1]
room = app / 'VenueVolume/Environments/Classroom'
manifest = json.loads((room / 'environment.json').read_text())
assert hashlib.sha256((room / 'environment.usdz').read_bytes()).hexdigest() == manifest['asset']['sha256']
assert (room / 'environment.usdz').read_bytes() == (repo / 'apps/room2blender/output/environment.usdz').read_bytes()
fixture = app / 'VenueVolume/FixtureAssets/RogueR1X'
metadata = json.loads((fixture / 'fixture.json').read_text())
runtime = next(a for a in metadata['model']['artifacts'] if a['role'] == 'runtime')
assert hashlib.sha256((fixture / 'fixture.usdz').read_bytes()).hexdigest() == runtime['sha256']
assert (fixture / 'fixture.usdz').read_bytes() == (repo / 'assets/fixtures/chauvet-professional/rogue-r1x-spot/models/fixture.usdz').read_bytes()
assert {p['name'] for p in metadata['model']['parts']} >= {'base', 'yoke', 'head'}
assert metadata['model']['emitters'][0]['optical_axis'] == [0, 0, -1]
print('Asset checks passed: exact room and fixture copies, SHA-256, articulation and emitter metadata.')

catalog = json.loads((repo / 'assets/fixtures/runtime-catalog.json').read_text())
records = {p.parent.relative_to(repo / 'assets/fixtures').as_posix()
           for p in (repo / 'assets/fixtures').glob('*/*/fixture.json')
           if json.loads(p.read_text())['model']['status'] == 'validated'}
assert {a['id'] for a in catalog} == records
generated = (app / 'Core/Sources/VenueVolumeCore/GeneratedFixtureCatalog.swift').read_text()
assert json.loads(generated.split('#"""\n', 1)[1].rsplit('\n"""#', 1)[0]) == catalog
for asset in catalog:
    source = repo / 'assets/fixtures' / asset['id']
    bundled = app / 'VenueVolume' / asset['resource']
    assert hashlib.sha256(bundled.read_bytes()).hexdigest() == asset['sha256'], asset['id']
    assert bundled.read_bytes() == (source / 'models/fixture.usdz').read_bytes(), asset['id']
    assert json.loads((source / 'models/rig.json').read_text())['descriptor'] == asset
    assert json.loads((source / 'validation/rig.json').read_text())['passed']
print(f'Catalog checks passed: {len(catalog)} exact bundled models, rig companions, generated Swift catalog and validation reports.')

mapped = app / 'VenueVolume/Environments/MappedRoom'
metadata = json.loads((mapped/'environment.json').read_text())
assert metadata['id'] == metadata['title'] == 'mappedRoom'
assert metadata['asset']['bytes'] == (mapped/'environment.usdz').stat().st_size
assert hashlib.sha256((mapped/'environment.usdz').read_bytes()).hexdigest() == metadata['asset']['sha256']
for file in ['environment.json', 'environment.usdz']:
    assert (mapped/file).read_bytes() == (repo/'apps/room2blender/mappedRoom/output'/file).read_bytes()
for key in ['colliders', 'surfaces', 'spawn', 'bounds', 'geometry']:
    assert metadata[key] == manifest[key], key
print('Mapped room checks passed: separate identity, exact authoring copies, unchanged geometry/colliders/surfaces/spawn.')
