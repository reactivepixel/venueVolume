#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/stryker-wash', 'width_m': 0.324, 'height_m': 0.399, 'depth_m': 0.222, 'profile': {'family': 'moving_wash', 'lens_count': 19, 'shell': 'round'}, 'source_urls': ['https://www.adj.com/products/stryker-wash', 'https://www.adj.com/cdn/shop/files/aff04e4f77e061376b58502065e4278f6f563981_STR100__IMG__001__3350049b2831.jpg?v=1776712421&width=800']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
