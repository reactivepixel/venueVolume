#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'antari/s-100x-snow-machine', 'width_m': 0.365, 'height_m': 0.409, 'depth_m': 0.505, 'profile': {'family': 'snow', 'body_style': 'compact rectangular snow machine with front outlet, top controls and hanging bracket', 'notes': 'Distinguish current S-100X from legacy S-100II; dimensions and fluid/control data match current X-series page.', 'generator': 'effects', 'enclosure': 'silver_machine', 'hanging_bracket': True, 'manual_equipment_tilt': True, 'output_kind': 'snow'}, 'source_urls': ['https://antari.com/products/s-100x/', 'https://www.antari.com/usermanual/S/S-100X/S-100X.pdf', 'https://www.antari.com/ProductGuide/2026/2026ProductGuide.pdf', 'https://antari.com/wp-content/uploads/S-100X_01.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
