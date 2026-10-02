#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chroma-q/color-force-ii-48', 'width_m': 1.181, 'height_m': 0.191, 'depth_m': 0.165, 'profile': {'family': 'batten', 'lens_count': 16, 'diffuser': True, 'manual_tilt': True}, 'source_urls': ['https://chroma-q.com/products/color-force-ii-48', 'https://chroma-q.com/media/cache/app_top_hero/12/cd/6788b53503465a4bbdbf64bb60ab.jpeg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
