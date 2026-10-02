#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'antari/sw-250-snow-machine', 'width_m': 0.365, 'height_m': 0.409, 'depth_m': 0.539, 'profile': {'family': 'snow', 'body_style': 'silver metal snow appliance with top LCD controls and front hose outlet', 'notes': 'Current SW-250 wireless unit; retain W-1 transmitter as included accessory metadata, not enclosure geometry.', 'generator': 'effects', 'enclosure': 'silver_machine', 'hanging_bracket': True, 'manual_equipment_tilt': True, 'output_kind': 'snow'}, 'source_urls': ['https://antari.com/zh-hant/products/sw-250/', 'https://www.antari.com/DM/S/SW-250/SW-250.pdf', 'https://antari.com/wp-content/uploads/SW-250_01.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
