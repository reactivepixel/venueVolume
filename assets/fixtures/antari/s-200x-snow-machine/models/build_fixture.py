#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'antari/s-200x-snow-machine', 'width_m': 0.365, 'height_m': 0.409, 'depth_m': 0.505, 'profile': {'family': 'snow', 'body_style': 'silver rectangular snow machine with top control panel, front hose outlet and suspension bracket', 'notes': "Do not include extension hose in enclosure bounds. The product guide's 3-pin note identifies the DMX connector; the current shared manual explicitly documents DMX512 and one channel for the S-200X.", 'generator': 'effects', 'enclosure': 'silver_machine', 'hanging_bracket': True, 'manual_equipment_tilt': True, 'output_kind': 'snow'}, 'source_urls': ['https://www.antari.com/ProductGuide/2026/2026ProductGuide.pdf', 'https://www.antari.com/usermanual/S/S-100X/S-100X.pdf', 'https://antari.com/wp-content/uploads/S-200X_01.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
