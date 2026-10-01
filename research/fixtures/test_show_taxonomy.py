"""Regression checks for product identity, classification and honest coverage."""
import csv,json,unittest
from pathlib import Path
from build_show_taxonomy import classify,ROOT

class ShowEquipmentTests(unittest.TestCase):
    def test_roles_are_not_source_or_transport(self):
        cases=[('pixel_controller','Pixelator Mini','control.pixel'),
               ('pixel_driver','PIXEL DRIVER 170','control.pixel'),
               ('power_supply','LRS-350-24','power.distribution'),
               ('mirror_motor','MBMHD3','lighting.effects.mirror_motor'),
               ('mirror_ball','M-2020','lighting.effects.mirror_ball'),
               ('jet','M-9','atmosphere.fog_jet'),
               ('co2_jet','CO2jet II','effects.co2'),
               ('connector','powerCON TRUE1','power.cable'),
               ('connector','NC5MXX','control.cable')]
        for family,name,expected in cases:
            with self.subTest(name=name):
                row={'manufacturer':'Test','name':name,'type':family,'subtype':''}
                self.assertEqual(classify(row,{'family':family}),expected)

    def test_combined_csv_preserves_json_and_pending_state(self):
        with (ROOT/'assets/fixtures/research/show-equipment-catalog.csv').open() as source:
            rows=list(csv.DictReader(source))
        self.assertEqual(len({(r['manufacturer'],r['name']) for r in rows}),len(rows))
        for row in rows:
            with self.subTest(name=row['name']):
                self.assertIsInstance(json.loads(row['data']),dict)
                images=json.loads(row['images']);self.assertIsInstance(images,list)
                self.assertTrue(all(isinstance(u,str) and u.startswith(('http://','https://')) for u in images))
                if row['asset_state']=='research_only':
                    self.assertEqual(row['model_state'],'not_built')
                    self.assertFalse(row['usdz_asset'])
                    self.assertTrue(row['asset_blocker'])
                else:
                    for key in ('blend_asset','usdz_asset','preview_asset','fixture_record'):
                        self.assertTrue((ROOT/row[key]).is_file())

    def test_coverage_is_representative_not_exhaustive(self):
        data=json.loads((ROOT/'assets/fixtures/research/show-equipment-taxonomy.json').read_text())
        self.assertFalse(data['summary']['exhaustive_model_catalog'])
        leaves=[c for c in data['categories'] if c['is_leaf']]
        self.assertEqual(sum(c['asset_count'] for c in leaves),data['summary']['asset_count'])
        for category in leaves:
            self.assertEqual(category['coverage']=='represented',category['asset_count']>0)
        for item in data['items']:
            record=json.loads((ROOT/'assets/fixtures'/item['id']/'fixture.json').read_text())
            output=record['model'].get('profile',{}).get('output_kind','light')
            if output!='light':self.assertEqual(record['model']['emitters'],[])

if __name__=='__main__':unittest.main()
