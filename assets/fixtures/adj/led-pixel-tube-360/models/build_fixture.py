#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/led-pixel-tube-360', 'width_m': 1.0, 'height_m': 0.05, 'depth_m': 0.05, 'profile': {'family': 'tube', 'body_style': 'round translucent polycarbonate pixel tube with end caps', 'notes': 'External controller is separate physical product; no native DMX attributed to the tube.', 'generator': 'equipment', 'output_kind': 'light'}, 'source_urls': ['https://www.adj.com/products/led-pixel-tube-360', 'https://www.adj.com/products/led-pixel-10c', 'https://www.adj.com/cdn/shop/files/429d3536aa084bddeeeb30bfad5c4762f264648f_LED075__IMG__001__adb6428d9066.jpg?v=1776713790&width=450']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
