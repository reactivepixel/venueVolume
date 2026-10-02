#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'antari/hz-400-hazer', 'width_m': 0.32, 'height_m': 0.325, 'depth_m': 0.51, 'profile': {'family': 'hazer', 'body_style': 'medium metal hazer with top handle, control panel, twin front nozzles and adjustable diverter', 'notes': 'Dual nozzle assembly is a meaningful visual distinction from HZ-350 and HZ-500.', 'generator': 'effects', 'enclosure': 'silver_hazer', 'output_kind': 'haze'}, 'source_urls': ['https://antari.com/products/hz-400/', 'https://antari.com/wp-content/uploads/HZ-400_01.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
