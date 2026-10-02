#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'antari/z-3000iii-fog-machine', 'width_m': 0.275, 'height_m': 0.278, 'depth_m': 0.712, 'profile': {'family': 'fogger', 'body_style': 'wide industrial fog machine with convex sheet-metal shell, LCD/dual controls and front outlet', 'notes': 'Model current III generation. Do not carry over an older 735 mm length from earlier brochure.', 'generator': 'effects', 'enclosure': 'silver_machine', 'hanging_bracket': False, 'output_kind': 'fog'}, 'source_urls': ['https://antari.com/products/z-3000iii/', 'https://www.antari.com/ProductGuide/2026/2026ProductGuide.pdf', 'https://antari.com/wp-content/uploads/Z-3000III_01.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
