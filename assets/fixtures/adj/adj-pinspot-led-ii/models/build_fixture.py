#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/adj-pinspot-led-ii', 'width_m': 0.099, 'height_m': 0.061, 'depth_m': 0.184, 'profile': {'family': 'pinspot', 'body_style': 'compact black cylindrical pinspot barrel with lens, bracket and cable', 'notes': 'Static beam optic; no moving scanner behavior. Body axes mapped from image/product form; bracket envelope estimated.', 'generator': 'equipment', 'output_kind': 'light'}, 'source_urls': ['https://www.adj.com/products/pinspot-led-ii', 'https://www.adj.com/cdn/shop/files/0340c0aad22443e2892abd64feb4d16bef72de3a_PIN222__IMG__001__4c296cfc78c8.jpg?v=1776712482&width=2048']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
