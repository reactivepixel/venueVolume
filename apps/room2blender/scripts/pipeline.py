#!/usr/bin/env python3
"""Reproducible capture -> reviewed specification -> Blender review bundle."""
import argparse
from contextlib import contextmanager
import fcntl
import hashlib
from importlib.metadata import version
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone

from specification import draft, validate

APP = Path(__file__).resolve().parents[1]
SCRIPTS = APP / 'scripts'
PIPELINE_VERSION = '1.1.0'


def digest(path):
    with Path(path).open('rb') as file:
        return hashlib.file_digest(file, 'sha256').hexdigest()


def key(data):
    return hashlib.sha256(json.dumps(data, sort_keys=True, separators=(',', ':'), allow_nan=False).encode()).hexdigest()


def write(path, data):
    path = Path(path)
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(json.dumps(data, indent=2, allow_nan=False)+'\n')
    temporary.replace(path)


def inventory(root, paths):
    return {str(p.relative_to(root)): digest(p) for folder in paths for p in sorted(folder.rglob('*'))
            if p.is_file() and not p.name.endswith('.blend1')}


def verified(root):
    manifest = json.loads((root/'artifacts.json').read_text())
    for name, expected in manifest.items():
        path = (root/name).resolve()
        if not path.is_relative_to(root.resolve()) or not path.is_file() or digest(path) != expected:
            raise ValueError(f'Cached artifact changed or missing: {path}. Preserved existing files; use a new --out project.')
    return manifest


def status(project, state, **fields):
    write(project/'status.json', {'pipeline_version': PIPELINE_VERSION, 'state': state,
          'updated_at': datetime.now(timezone.utc).isoformat(), **fields})
    print(state.replace('_', ' ').upper(), flush=True)


@contextmanager
def project_lock(path):
    path.mkdir(parents=True, exist_ok=True)
    marker = path/'.room2blender-project'
    if not marker.exists():
        if any(path.iterdir()):
            raise ValueError('--out must be empty or an existing room2blender project')
        marker.touch()
    with (path/'.lock').open('a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ValueError('Another room2blender process is using this output project') from None
        try:
            yield
        finally:
            fcntl.flock(lock, fcntl.LOCK_UN)


def command_version(command):
    result = subprocess.run(command, capture_output=True, text=True, timeout=30, check=True)
    return result.stdout.strip()


def blender_path(value):
    binary = value or os.environ.get('BLENDER_BIN') or shutil.which('blender')
    if not binary:
        raise ValueError('Blender is required to build. Install Blender 4.5+ or pass --blender /path/to/blender')
    resolved = shutil.which(binary) or str(Path(binary).expanduser().resolve())
    if not Path(resolved).is_file():
        raise ValueError(f'Blender executable not found: {resolved}')
    return resolved


def stage(command, log):
    print('  Log:', log, flush=True)
    with log.open('w') as stream:
        result = subprocess.run(command, stdout=stream, stderr=subprocess.STDOUT)
    if result.returncode:
        tail = '\n'.join(log.read_text(errors='replace').splitlines()[-12:])
        raise RuntimeError(f'Stage exited {result.returncode}; log: {log}\n{tail}')


def report(root):
    from PIL import Image, ImageDraw, ImageFont
    names = ['front-left', 'front-right', 'rear-right', 'rear-left']
    sheet = Image.new('RGB', (1440, 1160), '#17212a')
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=20)
    for i, name in enumerate(names):
        x, y = i % 2 * 720, i // 2 * 580
        photo = Image.open(root/'output'/f'cutaway-{name}.png').convert('RGB')
        photo.thumbnail((704,528))
        sheet.paste(photo, (x+8, y+38))
        draw.text((x+16, y+9), name.upper()+' / ISOMETRIC', fill='white', font=font)
    sheet.save(root/'output/cutaways.jpg', quality=92)
    spec = json.loads((root/'room_spec.json').read_text())
    checks = json.loads((root/'output/validation.json').read_text())
    import html
    title = html.escape(spec.get('title', spec['id']))
    assumptions = ''.join('<li>'+html.escape(str(a))+'</li>' for a in spec['assumptions'])
    cards = ''.join(f'<figure><img src="output/cutaway-{n}.png"><figcaption>{n}</figcaption></figure>' for n in names)
    (root/'index.html').write_text(f'''<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>{title}</title>
<style>body{{font:16px system-ui;background:#17212a;color:#ecf0f4;max-width:1400px;margin:32px auto;padding:0 24px}}a{{color:#8cdaef}}.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:20px}}figure{{margin:0}}img{{width:100%}}figcaption{{padding:8px 0}}li{{margin:8px 0}}</style>
<h1>{title}</h1><p>{html.escape(spec['scale_status'])}</p>
<p><a href="output/room.blend">Blender model</a> · <a href="output/environment.usdz">Vision Pro USDZ</a> · <a href="output/environment.json">Environment manifest</a> · <a href="output/environment-validation.json">Export validation</a> · <a href="references/contact-sheet.jpg">Movie references</a> ·
<a href="room_spec.json">Reviewed specification</a> · <a href="output/validation.json">Validation</a></p>
<div class="grid">{cards}<figure><img src="output/interior.png"><figcaption>Interior</figcaption></figure>
<figure><img src="output/floor-plan.png"><figcaption>Plan</figcaption></figure></div>
<h2>Assumptions</h2><ul>{assumptions}</ul><p>Checks passed: {sum(c['passed'] for c in checks['checks'])}/{len(checks['checks'])}.
Geometry validation does not establish real-world dimensional accuracy.</p></html>''')


def capture(movie, project, count, times, spec):
    if not movie.is_file():
        raise ValueError(f'Movie does not exist: {movie}')
    source_hash = digest(movie)
    if spec is not None:
        validate(spec, source_hash)
    provenance = {'pipeline_version': PIPELINE_VERSION, 'source_sha256': source_hash,
                  'source_name': movie.name, 'count': count, 'times': times,
                  'extractor_sha256': digest(SCRIPTS/'extract_references.py'),
                  'ffmpeg': command_version(['ffmpeg','-version']),
                  'ffprobe': command_version(['ffprobe','-version']), 'python': sys.version,
                  'dependencies': {name: version(name) for name in ('numpy','pillow','opencv-python-headless')}}
    capture_key = key(provenance)
    final = project/'captures'/capture_key
    if final.exists():
        verified(final)
        print('Reusing verified reference images.', flush=True)
        return final, source_hash
    final.parent.mkdir(exist_ok=True)
    work = project/'.work'
    work.mkdir(exist_ok=True)
    status(project, 'extracting', source_sha256=source_hash)
    with tempfile.TemporaryDirectory(dir=work, prefix='capture-') as directory:
        temp = Path(directory)
        try:
            command = [sys.executable, str(SCRIPTS/'extract_references.py'), str(movie), '--project', str(temp), '--count', str(count)]
            if times:
                command += ['--times', ','.join(str(t) for t in times)]
            stage(command, temp/'extract.log')
            manifest = json.loads((temp/'references/manifest.json').read_text())
            if manifest['sha256'] != source_hash:
                raise ValueError('Source movie changed during extraction; retry with an unchanged copy')
            write(temp/'provenance.json', provenance)
            files = inventory(temp, [temp/'references'])
            files['provenance.json'] = digest(temp/'provenance.json')
            write(temp/'artifacts.json', files)
            shutil.move(str(temp), str(final))
        except BaseException:
            failures = project/'failures'
            failures.mkdir(exist_ok=True)
            shutil.copytree(temp, failures/temp.name, dirs_exist_ok=True)
            raise
    return final, source_hash


def build(project, capture_dir, source_hash, spec, args):
    validate(spec, source_hash)
    verified(capture_dir)
    for group in spec.get('shell_evidence', {}).values():
        for reference in group:
            path = (capture_dir/'references'/reference).resolve()
            if not path.is_relative_to((capture_dir/'references').resolve()) or not path.is_file():
                raise ValueError(f'Specification evidence is missing: {reference}; preserve its reference_times or revise the reviewed specification')
    binary = blender_path(args.blender)
    blender_version = command_version([binary, '--version'])
    import re
    match = re.search(r'Blender (\d+)\.(\d+)', blender_version)
    if not match or tuple(map(int, match.groups())) < (4,5):
        raise ValueError('Blender 4.5 or newer is required')
    provenance = {'pipeline_version': PIPELINE_VERSION, 'source_sha256': source_hash,
                  'capture': capture_dir.name, 'specification': spec,
                  'settings': {'width': args.width, 'samples': args.samples, 'device': args.device, 'seed': 0},
                  'blender_version': blender_version, 'blender_binary_sha256': digest(binary),
                  'scripts': {p.name:digest(p) for p in sorted(SCRIPTS.glob('*.py'))},
                  'lock_sha256': digest(APP/'uv.lock')}
    run_key = key(provenance)
    final = project/'runs'/run_key
    if final.exists():
        verified(final)
        status(project, 'complete', run=str(final.relative_to(project)), capture=str(capture_dir.relative_to(project)), source_sha256=source_hash, cached=True)
        print('Verified cached bundle:', final/'index.html')
        return 0
    final.parent.mkdir(exist_ok=True)
    work = project/'.work'
    work.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(dir=work, prefix='build-') as directory:
        temp = Path(directory)
        try:
            shutil.copytree(capture_dir/'references', temp/'references')
            write(temp/'room_spec.json', spec)
            write(temp/'provenance.json', provenance)
            logs = temp/'logs'
            logs.mkdir()
            source = 'build_room.py' if spec['recipe'] == 'classroom-v1' else 'build_boxes.py'
            common = [binary, '--factory-startup', '-b', '--python-exit-code', '1']
            status(project, 'building', source_sha256=source_hash, capture=str(capture_dir.relative_to(project)))
            build_args = ['--project', str(temp), '--blend-name', 'room.blend', '--no-render', '--width', str(args.width), '--samples', str(args.samples)]
            if args.device == 'cpu':
                build_args += ['--cpu']
            stage(common+['--python', str(SCRIPTS/source), '--']+build_args, logs/'build.log')
            blend = temp/'output/room.blend'
            status(project, 'rendering', capture=str(capture_dir.relative_to(project)), source_sha256=source_hash)
            stage([binary, '--factory-startup', '-b', str(blend), '--python-exit-code', '1', '--python', str(SCRIPTS/'render_review.py'), '--', '--project', str(temp)], logs/'render.log')
            status(project, 'validating', capture=str(capture_dir.relative_to(project)), source_sha256=source_hash)
            stage([binary, '--factory-startup', '-b', str(blend), '--python-exit-code', '1', '--python', str(SCRIPTS/'validate_room.py'), '--', '--project', str(temp)], logs/'validate.log')
            status(project, 'exporting', capture=str(capture_dir.relative_to(project)), source_sha256=source_hash)
            stage([binary, '--factory-startup', '-b', str(blend), '--python-exit-code', '1', '--python', str(SCRIPTS/'export_environment.py'), '--', '--project', str(temp)], logs/'export.log')
            report(temp)
            # Backup is a generated pre-render save, not a hand-edited user file.
            (temp/'output/room.blend1').unlink(missing_ok=True)
            files = inventory(temp, [temp/'references', temp/'output'])
            for name in ('index.html','room_spec.json','provenance.json'):
                files[name] = digest(temp/name)
            write(temp/'artifacts.json', files)
            shutil.move(str(temp), str(final))
        except BaseException:
            failures = project/'failures'
            failures.mkdir(exist_ok=True)
            saved = failures/temp.name
            shutil.copytree(temp, saved, dirs_exist_ok=True)
            print('Failed-stage files preserved:', saved, file=sys.stderr)
            raise
    status(project, 'complete', run=str(final.relative_to(project)), capture=str(capture_dir.relative_to(project)), source_sha256=source_hash, cached=False)
    print('Review bundle:', final/'index.html')
    return 0


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--version', action='version', version=PIPELINE_VERSION)
    subs = p.add_subparsers(dest='command', required=True)
    run = subs.add_parser('run', help='Extract a movie; build when a reviewed specification is supplied')
    run.add_argument('movie', type=Path)
    run.add_argument('--out', type=Path, required=True)
    run.add_argument('--count', type=int, default=16)
    run.add_argument('--times', help='Comma-separated reference times; otherwise evenly distributed')
    again = subs.add_parser('build', help='Build from an existing capture without needing the source movie')
    again.add_argument('project', type=Path)
    for command in (run, again):
        command.add_argument('--spec', type=Path, required=command is again)
        command.add_argument('--blender')
        command.add_argument('--width', type=int, default=1440)
        command.add_argument('--samples', type=int, default=32)
        command.add_argument('--device', choices=('cpu','cuda'), default='cpu')
    a = p.parse_args(argv)
    if a.width < 320 or a.width > 4096 or a.width % 4 or not 1 <= a.samples <= 512:
        p.error('width must be 320–4096 and divisible by 4; samples must be 1–512')
    if a.command == 'run' and not 1 <= a.count <= 128:
        p.error('count must be 1–128')
    project = (a.out if a.command == 'run' else a.project).expanduser().resolve()
    try:
        with project_lock(project):
            try:
                spec = json.loads(a.spec.read_text()) if a.spec else None
                if a.command == 'run':
                    times = [float(v) for v in a.times.split(',')] if a.times else (spec or {}).get('reference_times')
                    capture_dir, source_hash = capture(a.movie.expanduser().resolve(), project, a.count, times, spec)
                    status(project, 'references_ready', capture=str(capture_dir.relative_to(project)), source_sha256=source_hash)
                else:
                    previous = json.loads((project/'status.json').read_text())
                    capture_dir = (project/previous['capture']).resolve()
                    if not capture_dir.is_relative_to(project/'captures'):
                        raise ValueError('Invalid capture path in project status')
                    source_hash = previous['source_sha256']
                if spec is None:
                    draft_path = project/f'room_spec.{source_hash[:12]}.draft.json'
                    if not draft_path.exists():
                        write(draft_path, draft(source_hash))
                    status(project, 'review_required', capture=str(capture_dir.relative_to(project)), source_sha256=source_hash,
                           draft=str(draft_path.relative_to(project)))
                    print('References:', capture_dir/'references/contact-sheet.jpg')
                    print('Review and complete:', draft_path)
                    print('Then: room2blender build PROJECT --spec REVIEWED_SPEC.json')
                    return 3
                return build(project, capture_dir, source_hash, spec, a)
            except (Exception, KeyboardInterrupt) as error:
                previous = json.loads((project/'status.json').read_text()) if (project/'status.json').exists() else {}
                previous.pop('state', None)
                previous.pop('updated_at', None)
                previous.pop('pipeline_version', None)
                status(project, 'failed', **{**previous, 'error':str(error) or 'Interrupted'})
                raise
    except (Exception, KeyboardInterrupt) as error:
        print('room2blender:', str(error) or 'Interrupted', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
