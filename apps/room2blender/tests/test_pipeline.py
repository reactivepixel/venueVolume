import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

APP = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(APP/'scripts'))
from pipeline import digest, inventory, key, project_lock, verified, write
from specification import validate

CACHE = APP/'.cache/tests'
CACHE.mkdir(parents=True, exist_ok=True)


class Contracts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=CACHE)
        self.root = Path(self.temp.name)
        self.addCleanup(self.temp.cleanup)
        self.spec = json.loads((APP/'examples/box-room.template.json').read_text())
        self.spec.update(source_sha256='a'*64, review={'status':'reviewed','reviewer':'test','basis':'Synthetic fixture'})

    def test_review_and_source_are_required(self):
        validate(self.spec, 'a'*64)
        for field, value in [('source_sha256','b'*64), ('review',{'status':'draft'})]:
            spec = copy.deepcopy(self.spec)
            spec[field] = value
            with self.assertRaises(ValueError):
                validate(spec, 'a'*64)

    def test_rejects_invalid_geometry(self):
        for mutation in ('nan','duplicate','negative','missing_wall','bad_floor'):
            spec = copy.deepcopy(self.spec)
            if mutation == 'nan': spec['objects'][0]['position'][0] = float('nan')
            if mutation == 'duplicate': spec['objects'][1]['id'] = 'floor'
            if mutation == 'negative': spec['objects'][0]['size'][2] = -1
            if mutation == 'missing_wall': spec['objects'] = [o for o in spec['objects'] if o['id'] != 'left']
            if mutation == 'bad_floor': spec['objects'][0]['position'][2] = 1
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                validate(spec, 'a'*64)

    def test_cache_verifies_content_not_just_existence(self):
        (self.root/'output').mkdir()
        artifact = self.root/'output/model.blend'
        artifact.write_bytes(b'original')
        write(self.root/'artifacts.json', inventory(self.root, [self.root/'output']))
        verified(self.root)
        artifact.write_bytes(b'manual edits')
        with self.assertRaisesRegex(ValueError, 'changed or missing'):
            verified(self.root)
        self.assertEqual(artifact.read_bytes(), b'manual edits')

    def test_cache_key_is_order_independent_and_changes_with_inputs(self):
        self.assertEqual(key({'b':2,'a':1}), key({'a':1,'b':2}))
        self.assertNotEqual(key({'samples':16}), key({'samples':32}))

    def test_unrelated_output_directory_is_protected(self):
        marker = self.root/'user-file.txt'
        marker.write_text('keep')
        with self.assertRaisesRegex(ValueError, 'empty'):
            with project_lock(self.root):
                pass
        self.assertEqual(marker.read_text(), 'keep')

    def test_concurrent_project_lock(self):
        project = self.root/'project'
        with project_lock(project):
            with self.assertRaisesRegex(ValueError, 'Another'):
                with project_lock(project):
                    pass


@unittest.skipUnless(os.environ.get('BLENDER_BIN'), 'Set BLENDER_BIN for actual FFmpeg/Blender end-to-end tests')
class EndToEnd(unittest.TestCase):
    def test_review_boundary_build_repeat_cache_and_tamper(self):
        with tempfile.TemporaryDirectory(dir=CACHE) as directory:
            root = Path(directory)
            movie = root/'short room clip.mov'
            subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-f','lavfi','-i',
                            'testsrc2=size=320x240:rate=10','-t','2','-c:v','libx264','-y',str(movie)], check=True)
            cli = [sys.executable, str(APP/'scripts/pipeline.py')]
            project = root/'review project'
            def call(arguments, expected=0):
                result = subprocess.run(cli+arguments, text=True, capture_output=True)
                self.assertEqual(result.returncode, expected, result.stdout+'\n'+result.stderr)
                return json.loads((project/'status.json').read_text())
            state = call(['run',str(movie),'--out',str(project),'--count','4'], 3)
            self.assertEqual(state['state'], 'review_required')
            self.assertFalse(list(project.rglob('*.blend')))
            spec = json.loads((APP/'examples/box-room.template.json').read_text())
            spec.update(source_sha256=digest(movie), review={'status':'reviewed','reviewer':'integration test','basis':'Synthetic geometry; not inferred from test video'})
            spec_path = root/'reviewed.json'
            write(spec_path, spec)
            command = ['build',str(project),'--spec',str(spec_path),'--width','320','--samples','1']
            state = call(command)
            run = project/state['run']
            first_report = json.loads((run/'output/validation.json').read_text())
            self.assertTrue(first_report['passed'])
            self.assertEqual(len(list((run/'output').glob('cutaway-*.png'))), 4)
            timestamp = (run/'output/room.blend').stat().st_mtime_ns
            state = call(command)
            self.assertTrue(state['cached'])
            self.assertEqual((run/'output/room.blend').stat().st_mtime_ns, timestamp)
            # A settings change creates a new bundle and keeps the prior one.
            state = call(command[:-1]+['2'])
            second = project/state['run']
            self.assertNotEqual(second, run)
            self.assertEqual(json.loads((second/'output/validation.json').read_text())['geometry_sha256'], first_report['geometry_sha256'])
            self.assertTrue((run/'output/room.blend').exists())
            # Independent extraction + build reproduces reference bytes and geometry.
            other = root/'independent project'
            result = subprocess.run(cli+['run',str(movie),'--out',str(other),'--count','4','--spec',str(spec_path),'--width','320','--samples','1'], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout+'\n'+result.stderr)
            other_state = json.loads((other/'status.json').read_text())
            other_run = other/other_state['run']
            self.assertEqual(json.loads((other_run/'output/validation.json').read_text())['geometry_sha256'], first_report['geometry_sha256'])
            for frame in (run/'references').glob('*.jpg'):
                self.assertEqual(digest(frame), digest(other_run/'references'/frame.name))
            # Do not overwrite manual Blender edits while trying to reuse a cache.
            (run/'output/room.blend').write_bytes(b'edited by user')
            state = call(command, 1)
            self.assertEqual(state['state'], 'failed')
            self.assertEqual((run/'output/room.blend').read_bytes(), b'edited by user')


if __name__ == '__main__':
    unittest.main()
