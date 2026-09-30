#!/usr/bin/env python3
"""Validate fixture records and rebuild the Venue Volume catalogs. Python standard library only."""
import argparse
from datetime import date
import hashlib
import json
import math
from pathlib import Path
import re
import sys
from urllib.parse import urlparse


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def local_file(base, value):
    require(isinstance(value, str) and value and not Path(value).is_absolute(), 'Expected a relative file path')
    path = (base/value).resolve()
    require(path.is_relative_to(base.resolve()) and path.is_file(), f'Missing file or path escapes fixture: {value}')
    return path


def finite(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def validate(path, root):
    path = path.resolve()
    folder = path.parent
    relative = folder.relative_to((root/'assets/fixtures').resolve())
    require(len(relative.parts) == 2 and all(re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', p) for p in relative.parts), 'Expected manufacturer/model-variant slug directories')
    data = json.loads(path.read_text())
    require(data['schema_version'] == 1, 'Unsupported fixture schema')
    require(data['id'] == relative.as_posix(), 'Fixture ID must match its directory')
    require(type(data['revision']) is int and data['revision'] > 0, 'Invalid revision')
    date.fromisoformat(data['updated_at'])
    require(data['status'] in ('draft','researched','ready_for_visualization'), 'Invalid record status')
    for field in ('manufacturer','model'):
        require(isinstance(data['identity'][field], str) and data['identity'][field].strip(), f'Missing identity.{field}')
    sources = {s['id']: s for s in data['sources']}
    require(len(sources) == len(data['sources']), 'Duplicate source IDs')
    for source in sources.values():
        require(isinstance(source['id'], str) and source['id'].strip(), 'Source ID must be nonempty')
        require(source['kind'] in ('manufacturer_product','manufacturer_manual','manufacturer_drawing','manufacturer_asset','secondary','measurement'), 'Invalid source kind')
        require(source.get('title') and source.get('reuse_status'), 'Source needs title and reuse status')
        date.fromisoformat(source['accessed_at'])
        url = source.get('url')
        require((source['kind'] == 'measurement' and url is None) or
                (isinstance(url, str) and urlparse(url).scheme in ('http','https') and urlparse(url).netloc), 'Source needs a valid URL or user-measurement provenance')
        if source.get('file'):
            require(sha(local_file(folder, source['file'])) == source.get('sha256'), f'Source hash mismatch: {source["id"]}')

    def refs(ids):
        require(isinstance(ids, list) and all(s in sources for s in ids), 'Unknown source reference')

    def fact(item):
        refs(item['source_ids'])
        status = item['status']
        require(status in ('unknown','documented','measured','estimated'), 'Invalid fact status')
        if status == 'unknown':
            require(item['value'] is None, 'Unknown facts must use null')
        else:
            require(item['value'] is not None, 'Known fact has no value')
        if status in ('documented','measured'):
            require(item['source_ids'], 'Known fact needs evidence')
        if status == 'estimated':
            require(item.get('note'), 'Estimate needs an explanatory note')
        if isinstance(item['value'], float):
            require(math.isfinite(item['value']), 'Nonfinite fact')

    for axis in ('width','height','depth'):
        item = data['dimensions'][axis]
        fact(item)
        require(item['unit'] == 'm', 'Outer dimensions must use meters')
        require(item['value'] is None or (finite(item['value']) and item['value'] > 0), 'Dimension must be positive or unknown')
    for group in ('optical','electrical','mechanical','control'):
        for item in data['features'][group].values():
            fact(item)
    for mode in data['dmx_modes']:
        require(mode.get('name') and type(mode['footprint']) is int and 1 <= mode['footprint'] <= 512, 'Invalid DMX mode')
        refs(mode['source_ids'])
        require(mode['source_ids'], 'DMX modes need evidence')
        require(mode['mapping_status'] in ('not_transcribed','transcribed','bench_verified'), 'Invalid mapping status')
        offsets = []
        for channel in mode['channels']:
            offset = channel['offset']
            require(type(offset) is int and 1 <= offset <= mode['footprint'], 'Channel offset exceeds mode footprint')
            offsets.append(offset)
            require(channel.get('parameter') and channel['resolution_bits'] in (8,16), 'Invalid channel definition')
            if channel.get('fine_offset') is not None:
                require(channel['resolution_bits'] == 16 and type(channel['fine_offset']) is int and
                        1 <= channel['fine_offset'] <= mode['footprint'] and channel['fine_offset'] != offset, 'Invalid fine-channel offset')
            ranges = sorted(channel['ranges'], key=lambda r: r['min'])
            previous = -1
            for segment in ranges:
                require(type(segment['min']) is int and type(segment['max']) is int and
                        previous < segment['min'] <= segment['max'] < 2**channel['resolution_bits'] and segment.get('meaning'), 'Invalid/overlapping DMX ranges')
                previous = segment['max']
        require(len(offsets) == len(set(offsets)), 'Duplicate DMX offsets')
        if mode['mapping_status'] != 'not_transcribed':
            require(set(offsets) == set(range(1, mode['footprint']+1)), 'Transcribed mode must account for every channel')
        if mode['mapping_status'] == 'bench_verified':
            local_file(folder, mode['test_record'])
    model = data['model']
    require(model['status'] in ('not_built','unscaled_draft','scaled','validated'), 'Invalid model status')
    require((model['units'],model['up_axis'],model['forward_axis']) == ('meters','Y','-Z'), 'Runtime convention must be meters / Y-up / -Z forward')
    artifacts = {}
    for artifact in model['artifacts']:
        require(artifact['role'] in ('authoring','runtime','generator','preview','validation'), 'Unknown artifact role')
        file = local_file(folder, artifact['file'])
        require(sha(file) == artifact['sha256'], f'Artifact hash mismatch: {file.name}; preserve manual edits')
        artifacts.setdefault(artifact['role'], []).append(file)
    if data['status'] == 'ready_for_visualization':
        require(model['status'] == 'validated', 'Ready fixture needs validated model')
        require(all(role in artifacts for role in ('authoring','runtime','generator','preview','validation')), 'Ready fixture is missing required artifacts')
        require(len(set(artifacts['preview'])) >= 4, 'Ready fixture needs front, side, rear and three-quarter previews')
        require(model.get('origin') and model.get('reference_pose') and model['reference_pose'] == data['dimensions']['reference_pose'], 'Model and dimensional reference poses must match')
        require(model.get('representation') in ('manufacturer_cad','procedural_approximation'), 'Specify model representation')
        require(all(data['dimensions'][axis]['status'] in ('documented','measured') for axis in ('width','height','depth')), 'Ready fixture needs sourced scale dimensions')
        runtime = local_file(folder, 'models/fixture.usdz')
        report = json.loads(local_file(folder, 'validation/usdz.json').read_text())
        require(runtime in artifacts['runtime'] and folder/'validation/usdz.json' in artifacts['validation'], 'Register runtime and validation artifacts')
        require(report.get('passed') is True and report['asset_sha256'] == sha(runtime), 'USDZ report is stale or failed')
        require(report['bounds_m'] == model['bounds_m'], 'Record bounds disagree with actual USDZ report')
        expected = [data['dimensions'][a]['value'] for a in ('width','height','depth')]
        require(report['expected_dimensions_m'] == expected and report['tolerance_m'] == model['dimension_tolerance_m'], 'Scale report does not match current dimensional evidence')
        require(finite(model['dimension_tolerance_m']) and model['dimension_tolerance_m'] > 0, 'Missing dimensional tolerance')
        require(all(isinstance(model['bounds_m'][key], list) and len(model['bounds_m'][key]) == 3 and
                    all(finite(v) for v in model['bounds_m'][key]) for key in ('min','max')), 'Bounds must contain three finite coordinates')
        actual = [b-a for a,b in zip(model['bounds_m']['min'],model['bounds_m']['max'])]
        require(all(a > 0 and abs(a-b) <= model['dimension_tolerance_m'] for a,b in zip(actual,expected)), 'Model dimensions do not match evidence')
    for name in ('realitykit','hardware'):
        require(data['verification'][name] in ('not_tested','passed','failed'), 'Invalid verification status')
        if data['verification'][name] == 'passed':
            local_file(folder, data['verification'][name+'_test_record'])
    return data


def atomic(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix+'.tmp')
    temp.write_text(text)
    temp.replace(path)


def index(root):
    rows = []
    for path in sorted((root/'assets/fixtures').glob('*/*/fixture.json')):
        record = validate(path, root)
        note = root/'docs/08 Fixture Library/entries'/Path(record['id']+'.md')
        require(note.is_file(), f'Missing fixture note: {note}')
        rows.append({'id':record['id'], 'revision':record['revision'], 'status':record['status'],
                     'manufacturer':record['identity']['manufacturer'], 'model':record['identity']['model'],
                     'record':path.relative_to(root).as_posix(), 'record_sha256':sha(path),
                     'note':note.relative_to(root).as_posix()})
    atomic(root/'assets/fixtures/catalog.json', json.dumps({'schema_version':1,'fixtures':rows},indent=2)+'\n')
    def cell(value):
        return str(value).replace('|','\\|').replace('\n',' ').replace('[','\\[').replace(']','\\]')
    table = '# Fixture catalog\n\nGenerated from validated records by the fixture skill. Do not edit this index by hand.\n\n'
    table += '| Fixture | Revision | Status |\n| --- | --- | --- |\n'
    for row in rows:
        table += f'| [{cell(row["manufacturer"])} {cell(row["model"])}](entries/{row["id"]}.md) | {row["revision"]} | {row["status"]} |\n'
    if not rows:
        table += '\nNo hardware models have been added yet. Invoke the skill with a manufacturer and model.\n'
    atomic(root/'docs/08 Fixture Library/Catalog.md', table)
    print(f'Indexed {len(rows)} fixtures')


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('command', choices=('validate','index'))
    p.add_argument('entry', nargs='?', type=Path)
    p.add_argument('--root', type=Path, required=True)
    a = p.parse_args()
    try:
        root = a.root.resolve()
        if a.command == 'index':
            index(root)
        else:
            require(a.entry is not None, 'validate requires fixture.json')
            data = validate(a.entry, root)
            print(f'Valid record: {data["id"]} ({data["status"]}); source truth and runtime rendering need separate review')
    except (ValueError, KeyError, TypeError, OSError) as error:
        p.exit(1, f'Fixture library: {error}\n')


if __name__ == '__main__':
    main()
