#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'antari/w-101-wireless-bubble-machine', 'width_m': 0.264, 'height_m': 0.29, 'depth_m': 0.35, 'profile': {'family': 'bubble', 'body_style': 'compact silver bubble machine with top handle, single wheel opening and control switch', 'notes': 'Do not confuse W-101 with B-100; dimensions, wireless package and model identity are separate.', 'generator': 'equipment', 'output_kind': 'bubbles'}, 'source_urls': ['https://antari.com/products/w-101/', 'https://www.antari.com/ProductGuide/2026/2026ProductGuide.pdf', 'https://antari.com/wp-content/uploads/W-101_01.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
