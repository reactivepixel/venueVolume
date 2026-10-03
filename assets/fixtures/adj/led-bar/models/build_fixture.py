#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/led-bar', 'width_m': 0.5, 'height_m': 0.132, 'depth_m': 0.09, 'profile': {'family': 'batten', 'lens_count': 4, 'pixel_clusters': True}, 'source_urls': ['https://www.adj.com/products/led-bar', 'https://www.adj.com/cdn/shop/files/7bcfbe90e80e9aca47aa38adedb0ff216906529d_LED_BAR__IMG__001__a4051e307ea2.jpg?v=1776715774&width=2048']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
