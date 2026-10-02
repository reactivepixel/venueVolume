#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chroma-q/color-force-ii-12', 'width_m': 0.335, 'height_m': 0.218, 'depth_m': 0.19, 'profile': {'family': 'batten', 'lens_count': 4, 'diffuser': True, 'manual_tilt': True}, 'source_urls': ['https://chroma-q.com/products/color-force-ii-12', 'https://chroma-q.com/media/cache/app_top_hero/72/d9/2051c3ed2e2fb2fd36db9cf034a1.jpeg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
