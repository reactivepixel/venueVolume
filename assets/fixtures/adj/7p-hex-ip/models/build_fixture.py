#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/7p-hex-ip', 'width_m': 0.256, 'height_m': 0.2348, 'depth_m': 0.1704, 'profile': {'family': 'par', 'lens_count': 7, 'floor_yoke': True, 'body_style': 'ribbed', 'notes': 'Seven circular optics, cooling fins and double floor yoke.'}, 'source_urls': ['https://www.adj.com/products/7p-hex-ip', 'https://www.adj.com/cdn/shop/files/d067275be528798fdbc863962e9e0de2d25444f7_HEX700__IMG__001__ff60fa4bc937.jpg?v=1776713404&width=850', 'https://www.adj.eu/mwdownloads/download/link/id/1178']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
