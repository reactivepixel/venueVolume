#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'antari/z-1500iii-fog-machine', 'width_m': 0.235, 'height_m': 0.278, 'depth_m': 0.674, 'profile': {'family': 'fogger', 'body_style': 'low rectangular embossed fogger with top fluid reservoir and front outlet', 'notes': 'Distinct long low chassis from Antari Z-1000III. Product page and guide specify model-specific size and weight.', 'generator': 'effects', 'enclosure': 'silver_machine', 'hanging_bracket': False, 'output_kind': 'fog'}, 'source_urls': ['https://antari.com/products/z-1500iii/', 'https://www.antari.com/ProductGuide/2026/2026ProductGuide.pdf', 'https://antari.com/wp-content/uploads/Z-1500III_01.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
