"""Guard incomplete acquisition and public row-level status semantics."""
import copy
import json
import hashlib
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
import expand_catalog as acquisition
import publish_pipeline_status as status

class AcquisitionTests(unittest.TestCase):
    def setUp(self):
        self.item=dict(name='Sample',model_number='S1',manufacturer='Test',url='https://example.com/sample',type='moving light',subtype='spot',
            images=['https://example.com/sample.jpg'],data={'protocols':['DMX512']},
            dimensions={'width_m':.2,'height_m':.3,'depth_m':.2},modeling={'family':'moving_spot'},
            evidence=[{'url':'https://example.com/sample'}])

    def test_complete_acquisition_can_build(self):self.assertEqual(acquisition.issues(self.item),[])

    def test_no_shipping_size_or_infinite_geometry(self):
        for value in (None,0,float('inf'),float('nan')):
            item=copy.deepcopy(self.item);item['dimensions']['width_m']=value
            self.assertTrue(acquisition.issues(item))

    def test_errors_accept_agent_string_and_list(self):
        for value in ('Dimension conflict.',['Dimension conflict.']):
            item=copy.deepcopy(self.item);item['acquisition_errors']=value
            self.assertEqual(acquisition.issues(item),['Dimension conflict'])

    def test_unsupported_geometry_is_not_silently_substituted(self):
        self.item['modeling']['family']='twin_robot_heads'
        self.assertIn('The model needs a supported geometry profile',acquisition.issues(self.item))

    def test_unknown_optic_count_is_not_a_default_lens(self):
        self.item['modeling']['lens_count']=None
        self.assertIn('The visible optical module count has not been established',acquisition.issues(self.item))

    def test_csv_json_roundtrip_and_exact_error_column(self):
        row=acquisition.as_row(self.item)
        self.assertEqual(json.loads(row['images']),self.item['images'])
        self.assertEqual(json.loads(row['data'])['dimensions'],self.item['dimensions'])
        self.assertIn('pipelineErrors',row)

    def test_unbuilt_item_stays_blocked(self):
        with tempfile.TemporaryDirectory() as folder,patch.object(status,'ROOT',Path(folder)):
            row=acquisition.as_row(self.item);row['asset_blocker']='Width is unknown. Drawing is unavailable.'
            state,error=status.inspect(row)
            self.assertEqual(state,'blocked');self.assertIn('Width is unknown',error)
            self.assertEqual(error.count('.'),1)

    def test_no_false_success_on_partial_record(self):
        with tempfile.TemporaryDirectory() as folder,patch.object(status,'ROOT',Path(folder)):
            root=Path(folder)/'assets/fixtures/test/sample';root.mkdir(parents=True)
            (root/'fixture.json').write_text(json.dumps({'model':{'status':'not_built'}}))
            row=acquisition.as_row(self.item);row['usdz_asset']='assets/fixtures/test/sample/models/fixture.usdz'
            self.assertEqual(status.inspect(row)[0],'failed')

    def test_visual_failure_is_not_hidden_by_structural_pass(self):
        with tempfile.TemporaryDirectory() as folder,patch.object(status,'ROOT',Path(folder)),patch.object(status,'visual_issues',return_value={'test/sample':'Housing proportions require correction'}):
            root=Path(folder)/'assets/fixtures/test/sample'
            (root/'validation').mkdir(parents=True);(root/'models').mkdir()
            (root/'fixture.json').write_text(json.dumps({'model':{'status':'validated','artifacts':[]}}))
            for name in ('usdz','parity','rig'):(root/'validation'/f'{name}.json').write_text('{"passed":true}')
            bundle=Path(folder)/'apps/visionos/VenueVolume/fixture.usdz';bundle.parent.mkdir(parents=True)
            bundle.write_bytes(b'fixture')
            (root/'models/rig.json').write_text(json.dumps({'descriptor':{'resource':'fixture.usdz','sha256':hashlib.sha256(b'fixture').hexdigest()},'native_validation':'pending'}))
            row=acquisition.as_row(self.item);row['usdz_asset']='assets/fixtures/test/sample/models/fixture.usdz'
            state,error=status.inspect(row)
            self.assertEqual(state,'visual_review_pending')
            self.assertIn('Housing proportions',error);self.assertIn('Mac',error)

if __name__=='__main__':unittest.main()
