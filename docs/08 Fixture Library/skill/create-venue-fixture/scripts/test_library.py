"""Contract regressions; artifacts here are stubs, not a USDZ integration test."""
from copy import deepcopy
from pathlib import Path
import json
import tempfile
import unittest
import library


class LibraryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.folder = self.root/'assets/fixtures/test-maker/test-model'
        self.folder.mkdir(parents=True)
        self.entry = self.folder/'fixture.json'
        self.record = json.loads((Path(__file__).resolve().parents[1]/'assets/fixture-template.json').read_text())
        self.record.update(id='test-maker/test-model', updated_at='2026-09-29')
        self.record['identity'].update(manufacturer='Test Maker', model='Test Model')
        self.record['sources'] = [{'id':'drawing', 'url':'https://example.com/drawing',
            'title':'Synthetic test drawing', 'kind':'manufacturer_drawing',
            'accessed_at':'2026-09-29', 'document_revision':None, 'locator':None, 'reuse_status':'test only'}]

    def validate(self):
        self.entry.write_text(json.dumps(self.record))
        return library.validate(self.entry, self.root)

    def artifact(self, role, name, content='test stub'):
        file = self.folder/name
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text(content)
        self.record['model']['artifacts'].append({'role':role, 'file':name, 'sha256':library.sha(file)})

    def ready(self):
        self.record['status'] = 'ready_for_visualization'
        for axis, value in zip(('width','height','depth'), (0.4,0.6,0.3)):
            self.record['dimensions'][axis].update(value=value,status='documented',source_ids=['drawing'])
        self.record['dimensions']['reference_pose'] = 'neutral'
        model = self.record['model']
        model.update(status='validated', origin='base center', reference_pose='neutral',
                     representation='procedural_approximation', dimension_tolerance_m=0.002,
                     bounds_m={'min':[0,0,0], 'max':[0.4,0.6,0.3]})
        for role, name in [('authoring','models/fixture.blend'), ('runtime','models/fixture.usdz'),
                           ('generator','models/build_fixture.py')]:
            self.artifact(role, name)
        for name in ('front','rear','side','quarter'):
            self.artifact('preview',f'previews/{name}.png')
        self.artifact('validation','validation/usdz.json', json.dumps({
            'passed':True, 'asset_sha256':library.sha(self.folder/'models/fixture.usdz'),
            'bounds_m':model['bounds_m'], 'expected_dimensions_m':[0.4,0.6,0.3], 'tolerance_m':0.002}))

    def test_draft_and_catalog(self):
        self.validate()
        note = self.root/'docs/08 Fixture Library/entries/test-maker/test-model.md'
        note.parent.mkdir(parents=True)
        note.write_text('# Test fixture\n')
        library.index(self.root)
        catalog = json.loads((self.root/'assets/fixtures/catalog.json').read_text())
        self.assertEqual(catalog['fixtures'][0]['record_sha256'],library.sha(self.entry))

    def test_unknown_is_not_zero(self):
        self.record['dimensions']['width']['value'] = 0
        with self.assertRaisesRegex(ValueError,'Unknown facts'):
            self.validate()

    def test_missing_evidence(self):
        self.record['dimensions']['width'].update(value=0.4,status='documented',source_ids=['missing'])
        with self.assertRaisesRegex(ValueError,'Unknown source'):
            self.validate()

    def test_manual_edits_detected(self):
        self.artifact('authoring','models/fixture.blend')
        (self.folder/'models/fixture.blend').write_text('manual edit')
        with self.assertRaisesRegex(ValueError,'preserve manual edits'):
            self.validate()

    def test_path_escape(self):
        (self.folder.parent/'outside').write_text('test')
        self.record['model']['artifacts'] = [{'role':'runtime','file':'../outside','sha256':'unused'}]
        with self.assertRaisesRegex(ValueError,'escapes fixture'):
            self.validate()

    def test_incomplete_dmx_transcription(self):
        self.record['dmx_modes'] = [{'name':'Test', 'footprint':2, 'firmware':None, 'source_ids':['drawing'],
            'mapping_status':'transcribed', 'channels':[{'offset':1,'parameter':'dimmer',
            'resolution_bits':8,'ranges':[{'min':0,'max':255,'meaning':'intensity'}]}]}]
        with self.assertRaisesRegex(ValueError,'every channel'):
            self.validate()
        self.record['dmx_modes'][0]['mapping_status'] = 'not_transcribed'
        self.validate()

    def test_ready_requires_complete_evidence_and_unique_previews(self):
        self.ready()
        self.validate()
        baseline = deepcopy(self.record)
        for change, error in [
            (lambda r: r['model'].update(reference_pose=None), 'poses must match'),
            (lambda r: r['dimensions']['width'].update(status='estimated',note='guessed'), 'sourced scale'),
            (lambda r: r['model'].update(dimension_tolerance_m=0.003), 'current dimensional evidence'),
            (lambda r: r['model'].update(artifacts=[a for a in r['model']['artifacts'] if a['file'] != 'previews/rear.png']), 'previews'),
        ]:
            self.record = deepcopy(baseline)
            change(self.record)
            with self.assertRaisesRegex(ValueError,error):
                self.validate()

    def test_hardware_verification_requires_test_record(self):
        self.record['verification'].update(hardware='passed',hardware_test_record='validation/hardware.md')
        with self.assertRaisesRegex(ValueError,'Missing file'):
            self.validate()


if __name__ == '__main__':
    unittest.main()
