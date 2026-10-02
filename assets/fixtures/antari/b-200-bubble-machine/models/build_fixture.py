#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'antari/b-200-bubble-machine', 'width_m': 0.508, 'height_m': 0.391, 'depth_m': 0.251, 'profile': {'family': 'bubble', 'body_style': 'large black framed bubble appliance with triple wheel array and broad forward outlet', 'notes': "Current B-200 variant's three dual wheels differ from compact B-100 single double wheel.", 'generator': 'effects', 'enclosure': 'bubble_bank', 'bubble_rotor': True, 'output_kind': 'bubbles'}, 'source_urls': ['https://antari.com/products/b-200/', 'https://www.antari.com/DM/B/B-200/B-200.pdf', 'https://antari.com/wp-content/uploads/B-200-01.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
