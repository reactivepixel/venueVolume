#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/focus-wash-400', 'width_m': 0.21333, 'height_m': 0.4981, 'depth_m': 0.27843, 'profile': {'family': 'moving_wash', 'lens_count': 1, 'body_style': 'medium Fresnel wash head with large circular lens and yoke', 'notes': "Source uses both 9–42°, 9–43° and 10–41° zoom descriptions; record retains detailed spec's 9–43° range."}, 'source_urls': ['https://www.adj.com/products/focus-wash-400', 'https://www.adj.com/cdn/shop/files/f47caca4f21ed796c0be8a2c5f4cd420206163b7_FOC615__IMG__001__aec75c6e5447.jpg?v=1776712595']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
