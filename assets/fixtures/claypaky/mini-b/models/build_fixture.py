#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'claypaky/mini-b', 'width_m': 0.22, 'height_m': 0.346, 'depth_m': 0.186, 'profile': {'family': 'moving_wash', 'lens_count': 7, 'body_style': 'compact yoke head with central LED and six outer lenses', 'notes': 'Seven RGBW LEDs; keep central LED optically distinct from outer ring.'}, 'source_urls': ['https://www.claypaky.it/products/mini-b/', 'https://www.claypaky.it/wp-content/uploads/2022/10/Claypaky_NewProducts2019-2020_EN.pdf', 'https://www.claypaky.it/wp-content/uploads/2022/10/Claypaky_Mini-B.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
