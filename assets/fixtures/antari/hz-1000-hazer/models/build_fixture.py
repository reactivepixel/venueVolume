#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'antari/hz-1000-hazer', 'width_m': 0.51, 'height_m': 0.61, 'depth_m': 0.69, 'profile': {'family': 'hazer', 'body_style': 'large wheeled flight-case hazer with dual outlets, adjustable fan diverter and control panel', 'notes': 'Render the integrated wheeled enclosure; do not add separate flight-case geometry.', 'generator': 'effects', 'enclosure': 'road_case', 'outlet_count': 1, 'casters': True, 'output_kind': 'haze'}, 'source_urls': ['https://antari.com/products/hz-1000/', 'https://antari.com/wp-content/uploads/HZ-1000_01.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
