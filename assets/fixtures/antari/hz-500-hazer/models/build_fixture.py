#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'antari/hz-500-hazer', 'width_m': 0.375, 'height_m': 0.355, 'depth_m': 0.515, 'profile': {'family': 'hazer', 'body_style': 'black flight-case hazer with dual outlets and case latches', 'notes': 'The built-in case is part of the machine enclosure, distinct from shipping case dimensions. Product image shows the small square access hatch open; preserve this visual detail while using the closed-case listed envelope.', 'generator': 'effects', 'enclosure': 'road_case', 'outlet_count': 2, 'output_kind': 'haze'}, 'source_urls': ['https://antari.com/products/hz-500/', 'https://antari.com/wp-content/uploads/HZ-500_01.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
