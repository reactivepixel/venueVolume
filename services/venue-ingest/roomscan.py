"""roomScan artifact contract shared by intake, recovery and downloads."""
import hashlib
import importlib.util
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[2]
PIPELINE = ROOT / 'apps/roomScan/roomScan'


def progress(folder):
    try:
        return json.loads((folder / 'roomScan/status.json').read_text())
    except (OSError, ValueError):
        return {}


def artifact(folder, kind):
    project = (folder / 'roomScan').resolve()
    state = progress(folder)
    relative = {
        'model': f"{state.get('run', '')}/output/environment.usdz",
        'manifest': f"{state.get('run', '')}/output/environment.json",
        'blend': f"{state.get('run', '')}/output/room.blend",
        'draft': state.get('draft', ''),
        'references': f"{state.get('capture', '')}/references/contact-sheet.jpg",
    }.get(kind)
    if not relative:
        return None
    path = (project / relative).resolve()
    return path if path.is_relative_to(project) and path.is_file() else None


def ready(folder):
    if progress(folder).get('state') != 'complete':
        return False
    model, manifest = artifact(folder, 'model'), artifact(folder, 'manifest')
    if not model or not manifest:
        return False
    try:
        asset = json.loads(manifest.read_text())['asset']
        with model.open('rb') as stream:
            checksum = hashlib.file_digest(stream, 'sha256').hexdigest()
        return asset['file'] == model.name and asset['sha256'] == checksum and zipfile.is_zipfile(model)
    except (KeyError, TypeError, ValueError, OSError):
        return False


def save_review(folder, specification, source_hash):
    spec = importlib.util.spec_from_file_location('roomscan_specification', ROOT / 'apps/roomScan/scripts/specification.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.validate(specification, source_hash)
    path = folder / 'reviewed-room.json'
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(specification, indent=2, allow_nan=False) + '\n')
    temporary.replace(path)
