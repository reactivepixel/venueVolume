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
