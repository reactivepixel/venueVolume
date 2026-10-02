"""Assemble verified cached movie references into one build-compatible Fortress project.

Run from this task's worktree with apps/room2blender/.venv/bin/python.
No video decoding, metric reconstruction, or geometry approval is performed here.
"""
from pathlib import Path
import html
import json
import shutil
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'apps/room2blender/scripts'))
from pipeline import digest, inventory, key, project_lock, status, verified, write
from specification import draft
from PIL import Image, ImageDraw, ImageFont

PROJECT = ROOT/'outputs/the-fortress'
PRIOR = ROOT/'outputs/numbered-movies'
SELECTED = {1:[1,3,4,9,10,13,14], 2:[1,4,5,6,7,11,14,15,16], 3:[3,4,5,6,7,11,14,15]}
inputs = []
for number in (1,2,3):
    prior = PRIOR/str(number)
    state = json.loads((prior/'status.json').read_text())
    capture = (prior/state['capture']).resolve()
    if not capture.is_relative_to((prior/'captures').resolve()):
        raise ValueError('Prior capture path escapes its project')
    recorded = verified(capture)
    manifest = json.loads((capture/'references/manifest.json').read_text())
    assert manifest['sha256'] == state['source_sha256']
    movie = Path('/home/chapman/Projects/venueVolume/assets/raw_room_videos')/manifest['source']
    assert digest(movie) == manifest['sha256'], f'Source changed: {movie}'
    assert len(manifest['references']) == 16
    for ref in manifest['references']:
        name = ref['file']
        assert Path(name).name == name and f'references/{name}' in recorded
    inputs.append({'number':number, 'capture':capture, 'manifest':manifest,
                   'source':{'id':f'movie-{number}', 'file':manifest['source'], 'sha256':manifest['sha256'],
                             'duration_seconds':manifest['duration_seconds'], 'bytes':manifest['source_size_bytes']},
                   'capture_artifacts_sha256':digest(capture/'artifacts.json')})

# source_sha256 is a deterministic digest of the declared movie set, not one movie.
identity = {'kind':'movie_set', 'schema_version':1, 'sources':[i['source'] for i in inputs]}
source_hash = key(identity)
provenance = {'pipeline_version':'1.1.0', 'operation':'combine_verified_captures',
              'title':'The Fortress', 'source_kind':'movie_set', 'source_sha256':source_hash,
              'source_identity':identity, 'selection':SELECTED, 'assembler_sha256':digest(__file__),
              'inputs':[{'capture_id':i['capture'].name, 'source_id':i['source']['id'],
                         'artifacts_sha256':i['capture_artifacts_sha256']} for i in inputs],
              'processing':'Copied checksum-verified JPEGs without re-encoding; no video decode or image synthesis.',
              'identity_basis':'User confirmed all three numbered movies show the same large space, The Fortress.'}
capture_key = key(provenance)
with project_lock(PROJECT):
    final = PROJECT/'captures'/capture_key
    if not final.exists():
        (PROJECT/'captures').mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='.assemble-', dir=PROJECT) as tmp:
            stage = Path(tmp)
            refs = stage/'references'
            refs.mkdir()
            (refs/'source-manifests').mkdir()
            all_refs = []
            chosen = []
            for item in inputs:
                number = item['number']
                source_refs = item['capture']/'references'
                shutil.copyfile(source_refs/'manifest.json',refs/'source-manifests'/f'movie-{number}.json')
                shutil.copyfile(source_refs/'contact-sheet.jpg',refs/f'movie-{number}-contact-sheet.jpg')
                for index, reference in enumerate(item['manifest']['references'],1):
                    name = f'movie-{number}-{reference["file"]}'
                    shutil.copyfile(source_refs/reference['file'],refs/name)
                    entry = {**reference, 'file':name, 'source_id':item['source']['id'],
                             'source_movie':item['source']['file'], 'source_sha256':item['source']['sha256'],
                             'source_reference_file':reference['file'], 'sha256':digest(refs/name),
                             'selected_for_overview':index in SELECTED[number]}
                    assert entry['sha256'] == digest(source_refs/reference['file'])
                    all_refs.append(entry)
                    if entry['selected_for_overview']:
                        chosen.append(entry)
            # Keep all evidence; the 24-image sheet is only a focused overview.
            manifest = {'schema_version':1, 'source':'The Fortress / 1.MOV + 2.MOV + 3.MOV',
                        'source_kind':'movie_set', 'sha256':source_hash, 'source_identity':identity,
                        'sources':[i['source'] for i in inputs],
                        'timestamp_note':'Each requested_seek_seconds is relative to its named movie; no shared timeline or camera registration is implied.',
                        'selection':'48 existing reference images preserved; 24 chosen for room, seating, stage and rig coverage.',
                        'references':all_refs}
            write(refs/'manifest.json',manifest)
            font = ImageFont.load_default(size=16)
            sheet = Image.new('RGB',(1600,70+255*((len(chosen)+3)//4)),'#121c27')
            draw = ImageDraw.Draw(sheet)
            draw.text((16,12),'THE FORTRESS / ONE ROOM / THREE MOVIES',fill='white',font=font)
            draw.text((16,40),'24 overview views / 48 originals retained / dimensions unmeasured',fill='#b6c7d8',font=font)
            for index, ref in enumerate(chosen):
                x,y=(index%4)*400,70+(index//4)*255
                with Image.open(refs/ref['file']) as original:
                    photo=original.convert('RGB');photo.thumbnail((392,221))
                    sheet.paste(photo,(x+4,y))
                draw.text((x+8,y+225),f'{ref["source_movie"]} / ~{ref["requested_seek_seconds"]:.1f}s',fill='white',font=font)
            sheet.save(refs/'contact-sheet.jpg',quality=93)
            write(stage/'provenance.json',provenance)
            write(stage/'artifacts.json',{**inventory(stage,[refs]),'provenance.json':digest(stage/'provenance.json')})
            shutil.move(str(stage),str(final))
    verified(final)
    manifest = json.loads((final/'references/manifest.json').read_text())
    all_refs = manifest['references']
    def evidence(movie, indices):
        group=[r for r in all_refs if r['source_id']==f'movie-{movie}']
        return [group[index-1]['file'] for index in indices]
    spec_path = PROJECT/f'room_spec.{source_hash[:12]}.draft.json'
    if not spec_path.exists():
        spec=draft(source_hash)
        spec.update(id='the-fortress',title='The Fortress',source_kind='movie_set',source_identity=identity,
                    shell_evidence={'front':evidence(2,[11])+evidence(3,[4,11]),
                                    'left':evidence(1,[13]),'right':evidence(2,[4,5]),
                                    'rear':evidence(2,[14,15]),'ceiling':evidence(1,[4,14])+evidence(2,[1])},
                    observations=[
                        {'feature':'Stage and large rear stage display', 'evidence':evidence(3,[4,11])},
                        {'feature':'Flat-floor audience seating and aisles', 'evidence':evidence(2,[6,7,15])},
                        {'feature':'Tiered seating at the sides', 'evidence':evidence(1,[13])+evidence(2,[4,5])},
                        {'feature':'Suspended lighting trusses and curved overhead display', 'evidence':evidence(1,[4,14])+evidence(2,[1])},
                        {'feature':'Stage-front speaker boxes and access steps', 'evidence':evidence(3,[6,7,11,14])}],
                    coverage_gaps=['No measured width, depth, clear height, stage dimensions or known scale reference.',
                                   'Rear perimeter, concealed openings and behind-stage geometry are only partially visible.',
                                   'Exact seat counts, truss heights and fixture models/positions are not established.',
                                   'Some movie-3 overhead frames show ghosting; prefer clearer movie-1/movie-2 evidence.'])
        spec['assumptions']=[
            'User identifies all three videos as the same room, The Fortress.',
            'For the future blockout, front denotes the stage end; no surveyed coordinate alignment exists yet.',
            'Images are reused photographic references, not a registered photogrammetric reconstruction.',
            'People, screen content and changing show lighting are transient, not permanent room geometry.',
            'Dimensions and unseen geometry remain unknown; geometry review is still required.']
        write(spec_path,spec)
    status(PROJECT,'review_required',capture=str(final.relative_to(PROJECT)),source_sha256=source_hash,
           source_kind='movie_set',source_count=3,title='The Fortress',draft=spec_path.name)
    prefix=final.relative_to(PROJECT).as_posix()+'/references/'
    cards=''.join(f'<figure><a href="{prefix}{r["file"]}"><img loading="lazy" src="{prefix}{r["file"]}" alt="The Fortress reference from {r["source_movie"]}"></a><figcaption>{r["source_movie"]} · ~{r["requested_seek_seconds"]:.1f}s</figcaption></figure>' for r in all_refs)
    (PROJECT/'index.html').write_text(f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The Fortress · room reference review</title><style>body{{font:17px/1.6 system-ui,sans-serif;background:#101820;color:#e7edf3;max-width:1500px;margin:40px auto;padding:0 24px}}a{{color:#87cefa}}img{{width:100%;height:auto}}.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:20px}}figure{{margin:0}}summary{{cursor:pointer;font-size:1.4em}}li{{margin:8px 0}}</style><h1>The Fortress</h1><p>One room · 3 source movies · 48 reused reference images · 24 overview selections</p><p>All source videos and copied references passed SHA-256 checks. Original JPEGs were copied without re-encoding; no new video extraction was needed.</p><p><a href="{spec_path.name}">Single draft room specification</a> · <a href="{prefix}manifest.json">Combined source/frame manifest</a> · <a href="{final.relative_to(PROJECT).as_posix()}/provenance.json">Assembly provenance</a></p><h2>Room coverage</h2><ul><li>1.MOV: room, seating, side walls and overhead rig overview.</li><li>2.MOV: aisle, tiered seating and stage approach.</li><li>3.MOV: stage, access steps, screens and speaker details; some overhead views have ghosting.</li></ul><p><strong>Review required:</strong> room/stage dimensions and hidden perimeter geometry remain unknown. This project contains references and one evidence-linked draft, not a Blender or USDZ model.</p><a href="{prefix}contact-sheet.jpg"><img src="{prefix}contact-sheet.jpg" alt="The Fortress 24-image overview across all three movies"></a><details><summary>All 48 source references</summary><div class="grid">{cards}</div></details></html>''')
    write(PROJECT/'assembly-verification.json',{'passed':True,'source_movies_verified':3,'reused_reference_images':48,
          'overview_reference_images':24,'newly_extracted_images':0,'capture':str(final.relative_to(PROJECT)),
          'artifact_count':len(verified(final)),'draft':spec_path.name,'draft_status':'unreviewed_geometry',
          'source_kind':'movie_set','source_sha256':source_hash})
    print('The Fortress:',PROJECT/'index.html')
