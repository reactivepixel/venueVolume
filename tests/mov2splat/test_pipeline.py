"""Exercise frame budgets, resume invalidation, and image refresh without a GPU."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

APP = Path(__file__).resolve().parents[2] / 'apps/mov2splat'


class PipelineTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.movie = self.root / 'room.MOV'
        self.movie.write_bytes(b'test video')
        self.env = dict(os.environ, PATH=f'{self.bin}:{os.environ["PATH"]}', TEST_ROOT=str(self.root))
        self.stub('ffprobe', 'import json\nprint(json.dumps({"streams":[{"width":1920,"height":1080,"duration":"400"}]}))')
        self.stub('ffmpeg', '''import sys
from pathlib import Path
n=int(sys.argv[sys.argv.index('-frames:v')+1])
for i in range(1,n+1): Path(sys.argv[-1] % i).write_bytes(b'jpeg')
print('extraction invoked', flush=True)
''')
        self.stub('colmap', "import sys\nprint('mock reconstruction failure', flush=True)\nsys.exit(1)")

    def stub(self, name, body):
        p = self.bin / name
        p.write_text('#!/usr/bin/env python\n' + body + '\n')
        p.chmod(0o755)

    def run_pipeline(self, *options):
        return subprocess.run(['bash', str(APP/'scripts/run.sh'), *options, str(self.movie)],
                              env=self.env, text=True, capture_output=True, timeout=30)

    def test_default_and_explicit_frame_budget_and_resume(self):
        result = self.run_pipeline()
        self.assertEqual(result.returncode, 1)  # Deliberate stop at mock COLMAP.
        state = self.root/'room.gsplat/extract.json'
        self.assertEqual(json.loads(state.read_text())['frames'], 800)
        self.assertEqual(len(list((state.parent/'images').glob('*.jpg'))), 800)
        self.assertIn('pipeline failed at colmap', result.stdout)  # Logger tail drained.
        resumed = self.run_pipeline('--resume')
        self.assertNotIn('extraction invoked', resumed.stdout)
        changed = self.run_pipeline('--resume', '--frames', '1200')
        self.assertIn('extraction invoked', changed.stdout)
        self.assertEqual(len(list((state.parent/'images').glob('*.jpg'))), 1200)
        changed = self.run_pipeline('--resume', '--frames', '1200', '--scale', '1280')
        self.assertIn('extraction invoked', changed.stdout)
        (state.parent/'images/frame_00001.jpg').unlink()
        changed = self.run_pipeline('--resume', '--frames', '1200', '--scale', '1280')
        self.assertIn('extraction invoked', changed.stdout)

    def test_invalid_small_budget_is_not_silently_clamped(self):
        result = self.run_pipeline('--frames', '149')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('at least 150', result.stderr)
        self.assertFalse((self.root/'room.gsplat').exists())

    def test_stage_fingerprints(self):
        self.run_pipeline()
        work = self.root/'room.gsplat'
        model = work/'sparse/0'
        model.mkdir(parents=True)
        for name in ('cameras.bin', 'images.bin', 'points3D.bin'):
            (model/name).write_bytes(b'model')
        def state(action, **changes):
            flags = dict(input=str(self.movie), frames='800', scale='1600', blur='0', matcher='sequential')
            flags.update(changes)
            argv = ['python', str(APP/'scripts/state.py'), action, str(work/'sfm.json')]
            for key, value in flags.items(): argv += ['--'+key, value]
            return subprocess.run(argv, capture_output=True).returncode
        self.assertEqual(state('matches'), 1)  # Legacy/incomplete stage.
        self.assertEqual(state('save'), 0)
        self.assertEqual(state('matches'), 0)
        self.assertEqual(state('matches', matcher='exhaustive'), 1)
        self.assertEqual(state('matches', blur='100'), 1)
        self.movie.write_bytes(b'changed source')
        self.assertEqual(state('matches'), 1)
        self.assertEqual(state('save'), 0)
        (model/'images.bin').write_bytes(b'changed model')
        self.assertEqual(state('matches'), 1)
        (work/'sfm.json').write_text('incomplete json')
        self.assertEqual(state('matches'), 1)

    def test_resume_reuses_sfm_only_with_same_matching_settings(self):
        self.stub('colmap', """import struct, sys
from pathlib import Path
args=sys.argv[1:]
if args[0]=='mapper':
 p=Path(args[args.index('--output_path')+1])/'0'
 p.mkdir()
 for name,count in [('cameras.bin',1),('images.bin',800),('points3D.bin',10)]:
  (p/name).write_bytes(struct.pack('<Q',count))
print('colmap invoked', args[0], flush=True)
""")
        # Stop before the real trainer; other Python calls use the actual interpreter.
        wrapper = self.bin/'python'
        wrapper.write_text('#!' + sys.executable + '\n' +
            'import os, sys\n' +
            'if len(sys.argv)>1 and sys.argv[1].endswith("simple_trainer.py"): sys.exit(7)\n' +
            'os.execv(' + repr(sys.executable) + ', [' + repr(sys.executable) + '] + sys.argv[1:])\n')
        wrapper.chmod(0o755)
        first = self.run_pipeline()
        self.assertIn('pipeline failed at train', first.stdout)
        resumed = self.run_pipeline('--resume')
        self.assertIn('valid sparse/0 found; skipping SfM', resumed.stdout)
        changed = self.run_pipeline('--resume', '--exhaustive')
        self.assertNotIn('extraction invoked', changed.stdout)
        self.assertIn('colmap invoked exhaustive_matcher', changed.stdout)
        self.assertNotIn('skipping SfM', changed.stdout)

    def test_host_rebuilds_only_for_changed_image_inputs(self):
        app = self.root/'app'
        shutil.copytree(APP, app)
        self.stub('nvidia-smi', 'pass')
        self.stub('docker', '''import os, sys
from pathlib import Path
root=Path(os.environ['TEST_ROOT'])
a=sys.argv[1:]
if a[0]=='image':
 p=root/'image-hash'
 print(p.read_text() if p.exists() else '')
elif a[0]=='build':
 (root/'image-hash').write_text(a[a.index('--label')+1].split('=',1)[1])
 with (root/'builds').open('a') as f: f.write('build\\n')
''')
        def host():
            subprocess.run(['bash', str(app/'scripts/host.sh'), str(self.movie)],
                           env=self.env, check=True, capture_output=True, timeout=30)
        host()
        host()
        self.assertEqual((self.root/'builds').read_text().count('build'), 1)
        with (app/'scripts/run.sh').open('a') as f: f.write('\n# changed script\n')
        host()
        self.assertEqual((self.root/'builds').read_text().count('build'), 2)
        with (app/'scripts/state.py').open('a') as f: f.write('\n# changed helper\n')
        host()
        self.assertEqual((self.root/'builds').read_text().count('build'), 3)


if __name__ == '__main__':
    unittest.main()
