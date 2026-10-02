#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'antari/f-1-fazer', 'width_m': 0.275, 'height_m': 0.382, 'depth_m': 0.618, 'profile': {'family': 'hazer', 'body_style': 'long low rectangular metal fazer with front nozzle, top carry handle and air-pump housing', 'notes': 'Manufacturer describes both fog and haze output; model as equipment enclosure, not a light fixture.', 'generator': 'effects', 'enclosure': 'fazer_wedge', 'output_kind': 'haze'}, 'source_urls': ['https://antari.com/products/f-1/', 'https://antari.com/wp-content/uploads/F-1_01.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
