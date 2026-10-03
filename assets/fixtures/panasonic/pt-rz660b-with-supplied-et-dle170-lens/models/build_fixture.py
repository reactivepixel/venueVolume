#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'panasonic/pt-rz660b-with-supplied-et-dle170-lens', 'width_m': 0.498, 'height_m': 0.2, 'depth_m': 0.5808, 'profile': {'family': 'projector', 'body_style': 'large rectangular projector cabinet with lens protruding from front face', 'notes': 'Optional visual-equipment example. Model lens is included and represented at ET-DLE170 geometry; exact lens external dimensions require the ET-DLE170 drawing if a production model is built.', 'generator': 'equipment', 'output_kind': 'projection'}, 'source_urls': ['https://eu.connect.panasonic.com/gb/en/projectors/pt-rz660', 'https://na.panasonic.com/ns/246048_rz660_spec_en.pdf', 'https://eu.connect.panasonic.com/sites/default/files/media/image/2024-04/ca90fd90df4b2185ef5c10b1a03a7c59ad66e542.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
