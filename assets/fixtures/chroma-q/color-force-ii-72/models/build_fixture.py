#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chroma-q/color-force-ii-72', 'width_m': 1.759, 'height_m': 0.191, 'depth_m': 0.165, 'profile': {'family': 'batten', 'lens_count': 24, 'diffuser': True, 'manual_tilt': True}, 'source_urls': ['https://chroma-q.com/products/color-force-ii-72', 'https://chroma-q.com/media/cache/app_top_hero/3c/3b/783a4f1fc7d01481a9a4fd10c7b6.jpeg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
